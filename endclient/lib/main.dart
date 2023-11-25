import 'dart:io';

import 'package:esys_client/landing2.dart';
import 'package:esys_client/nearby_provider.dart';
import 'package:esys_client/services/identity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_model/LocalModel.dart';
import 'settings_provider.dart';
import 'v2/dashboard/dashboard.dart';

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
						child: const Landing2(),
					);
				}
			)
		);
	}

}
