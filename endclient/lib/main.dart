import 'dart:io';

import 'package:esys_client/service_graph.dart';
import 'package:esys_client/v2/landing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'local_model/LocalModel.dart';
import 'services/nearby.dart';
import 'services/settings.dart';

Future<void> main() async {

	var graph = defineServices();
	// await Future.delayed(const Duration(milliseconds: 50));

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
		var cs = ColorScheme.fromSwatch().copyWith(
			primary: const Color.fromARGB(255, 98, 85, 115),
			secondary: const Color.fromARGB(255, 146, 119, 68),
		);
		return MaterialApp(
			theme: ThemeData(
				colorScheme: cs,
				cardTheme: CardTheme.of(context).copyWith(
					margin: const EdgeInsets.all(16),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(20),
					)
				)
			),
			title: 'eSys Endurance',
			debugShowCheckedModeBanner: false,
			darkTheme: ThemeData.dark().copyWith(
				colorScheme: cs,
				cardTheme: CardTheme.of(context).copyWith(
					margin: const EdgeInsets.all(16),
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(20),
					)
				)
			),
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

	return b;
}
