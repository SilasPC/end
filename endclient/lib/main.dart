import 'dart:io';

import 'package:esys_client/service_graph.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/theme.dart';
import 'package:esys_client/v2/landing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'local_model/LocalModel.dart';
import 'services/nearby.dart';
import 'services/settings.dart';

Future<void> main() async {

	var graph = defineServices();

	FlutterError.onError = (details) {
		FlutterError.presentError(details);
		// graph.get<ServerConnection>().value?.reportError();
		// IGNORED: TODO: custom exception handler
	};

	WidgetsFlutterBinding.ensureInitialized();
	if (Platform.isWindows || Platform.isLinux) {
		sqfliteFfiInit();
		databaseFactory = databaseFactoryFfi;
	}

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

		var dark = context.select((Settings set) => set.darkTheme);

		var (lightTheme, darkTheme) = themeData();

		return MaterialApp(
			title: 'eSys Endurance',
			
			theme: lightTheme,
			darkTheme: darkTheme,
			themeMode: dark ? ThemeMode.dark : ThemeMode.light,

			debugShowCheckedModeBanner: false,
			home: Builder(
				builder: (context) {
					MediaQueryData mq = MediaQuery.of(context);
					// FEAT: scale everything ?
					var factor = context.watch<Settings>().largeUI ? 1.2 : 1;
					return MediaQuery(
						data: mq.copyWith(
							textScaleFactor: mq.textScaleFactor * factor,
						),
						child: const Landing(),
					);
				}
			)
		);
	}

}

ServiceGraph defineServices() {
	var b = ServiceGraph();

	b.add(SettingsService.createSync());
	b.deriveListenable((SettingsService s) => s.current);

	b.addListenable(LocalModel());

	b.pipe((Settings set, LocalModel lm) {
		lm.setServerUri(set.serverURI);
		lm.autoYield = set.autoYield;
	});

	b.addListenable(NearbyManager());
	b.pipe((NearbyManager nm, LocalModel lm) {
		for (var p in nm.devices) {
			lm.manager.addPeer(p);
		}
	});
	b.pipe((Settings set, NearbyManager nm) {
		nm.enabled = set.useP2P;
	});
	
	b.addListenableDep(ServerConnection.new);
	b.addListenableDep((LocalModel m) => PeerStates(m.manager));
	b.addListenableDep((LocalModel m) => SessionState(m.manager));

	b.pipe((ServerConnection conn, NearbyManager nm) {
		nm.autoConnect = !conn.inSync;
	});

	b.addListenable(IdentityService());	

	return b;
}
