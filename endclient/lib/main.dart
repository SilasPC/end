import 'dart:io';

import 'package:esys_client/local_model/states.dart';
import 'package:esys_client/nearby_provider.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'landing.dart';
import 'local_model/LocalModel.dart';
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

	runApp(
		const SettingsProvider(
			child: ModelProvider(
				child: VariousStatesProvider(
					child: NearbyProvider(
						child: MyApp(),
					)
				)
			)
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
			theme: ThemeData(colorScheme: cs),
			title: 'Endurance',
			debugShowCheckedModeBanner: false,
			darkTheme: ThemeData.dark(),
			home: Stack(
				children: [
					Image.asset(
						"assets/horse.jpg",
						height: MediaQuery.of(context).size.height,
						width: MediaQuery.of(context).size.width,
						fit: BoxFit.cover,
					),
					const LandingPage(),
				]
			)
		);
	}

}
