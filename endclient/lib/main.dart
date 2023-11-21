import 'dart:io';

import 'package:esys_client/landing2.dart';
import 'package:esys_client/nearby_provider.dart';
import 'package:esys_client/services/identity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
		SettingsProvider(
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
			title: 'eSys Endurance',
			debugShowCheckedModeBanner: false,
			darkTheme: ThemeData.dark(),
			home: const Landing2(),
		);
	}

}
