import 'dart:io';
import 'package:common/models/MetaModel.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/sqlite_db.dart';
import 'package:esys_client/service_graph.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/states.dart';
import 'package:esys_client/theme.dart';
import 'package:esys_client/v2/landing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/local_model.dart';
import 'services/nearby.dart';
import 'services/settings.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {

	var widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
	if (Platform.isWindows || Platform.isLinux) {
		sqfliteFfiInit();
		databaseFactory = databaseFactoryFfi;
	}

	FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

	var graph = defineServices();

	FlutterError.onError = (details) {
		FlutterError.presentError(details);
		// graph.get<ServerConnection>().value?.reportError();
		// IGNORED: TODO: custom exception handler
	};

	runApp(
		ServiceGraphProvider.value(
			graph: graph,
			child: const MyApp(),
		)
	);
}

class MyApp extends StatelessWidget {

	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {

		if (Platform.isAndroid || Platform.isIOS) {

			SystemChrome.setEnabledSystemUIMode(
				SystemUiMode.manual,
				overlays: [
					SystemUiOverlay.bottom
				]
			);

			final phoneSized = MediaQuery.sizeOf(context).shortestSide < 550;
			if (phoneSized) {
				SystemChrome.setPreferredOrientations([
					DeviceOrientation.portraitUp,
					DeviceOrientation.portraitDown,
				]);
			}

		}

		return Builder(
			builder: (context) {

				var dark = context.select((Settings set) => set.darkTheme);

				var (lightTheme, darkTheme) = themeData();

				// IGNORED: FEAT: use largeUI
				// context.select((Settings set) => set.largeUI);

				return MaterialApp(
					title: 'eSys Endurance',

					theme: lightTheme,
					darkTheme: darkTheme,
					themeMode: dark ? ThemeMode.dark : ThemeMode.light,

					debugShowCheckedModeBanner: false,
					home: const Landing(),
				);

			}
		);

	}

}

ServiceGraph defineServices() {

   var b = ServiceGraph();

   var id = IdentityService();
   var pm = PeerManager(
      id.identity!,
      SqliteDatabase.create,
      MetaModel()
   );

   b.addListenable(id);
   b.add(pm);

   // TODO: pipe id => peerman

	b.add(SettingsService.createSync());
	b.deriveListenable((SettingsService s) => s.current);

	b.addListenable(LocalModel());

	b.pipe((Settings set, ServerConnection conn) {
		conn.setServerUri(set.serverURI);
		conn.autoYield = set.autoYield;
	});

	b.addListenable(NearbyManager());
	b.pipe((NearbyManager nm, PeerManager man) {
		for (var p in nm.devices) {
			man.addPeer(p);
		}
	});
	b.pipe((Settings set, NearbyManager nm) {
		nm.enabled = set.useP2P;
	});

	b.addListenableDep(ServerConnection.new);
	b.addListenableDep((PeerManager m) => PeerStates(m));
	b.addListenableDep((PeerManager m) => SessionState(m));

	b.pipe((ServerConnection conn, NearbyManager nm) {
		nm.autoConnect = !conn.inSync;
	});


	return b;
}
