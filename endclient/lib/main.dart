import 'dart:io';

import 'package:esys_client/service_graph.dart';
import 'package:esys_client/landing2.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'local_model/LocalModel.dart';
import 'p2p/nearby.dart';
import 'settings_provider.dart';

Future<void> main() async {

	FlutterError.onError = (details) {
		FlutterError.presentError(details);
		// IGNORED: TODO: custom exception handler
	};

	WidgetsFlutterBinding.ensureInitialized();
	if (Platform.isWindows || Platform.isLinux) {
		sqfliteFfiInit();
		databaseFactory = databaseFactoryFfi;
	}

	var graph = defineServices();

	await Future.delayed(const Duration(milliseconds: 50));

	runApp(
		ServiceGraphProvider.value(
			graph: graph,
			child: const MyApp(),
		)
		/* SettingsProvider(
			child: ModelProvider(
				child: VariousStatesProvider(
					child: NearbyProvider(
						child: ChangeNotifierProvider<IdentityService>(
							lazy: false,
							create: (_) => IdentityService(),
							child: MyApp(),
						),
					)
				)
			)
		) */
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
			theme: ThemeData(colorScheme: cs),
			title: 'eSys Endurance',
			debugShowCheckedModeBanner: false,
			darkTheme: ThemeData.dark(),
			home: const Landing2(),
		);
	}

}

ServiceGraph defineServices() {
	var b = ServiceGraph();

	b.add(SettingsService.createSync());
	b.deriveListenable<SettingsService, Settings>((s) => s.current);

	b.addListenable(LocalModel());

	b.pipe<Settings, LocalModel>((s, lm) {
		lm.setServerUri(s.serverURI);
		lm.autoYield = s.autoYield;
	});

	b.addListenable(NearbyManager());
	b.pipe<NearbyManager, LocalModel>((nm, lm) {
		for (var p in nm.devices) {
			lm.manager.addPeer(p);
		}
	});
	
	b.addListenableDep(ServerConnection.new);
	b.addListenableDep<LocalModel, PeerStates>(
		(m) => PeerStates(m.manager)
	);
	b.addListenableDep<LocalModel, SessionState>(
		(m) => SessionState(m.manager)
	);

	return b;
}
