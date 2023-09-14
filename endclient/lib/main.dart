import 'package:esys_client/landing.dart';
import 'package:esys_client/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocalModel.dart';
import 'settings_provider.dart';

Future<void> main() async {
	FlutterError.onError = (details) {
		FlutterError.presentError(details);
		// TODO: custom exception handler
	};
	runApp(
		const SettingsProvider(
			child: ModelProvider(
				child: MyApp(),
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
			home: const LandingPage(),
		);
	}

}
