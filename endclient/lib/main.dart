import 'package:esys_client/landing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocalModel.dart';

Future<void> main() async {
	var m = LocalModel.instance;
   SharedPreferences.getInstance() // todo: move inside runApp
      .then((sp) {
         m.author = sp.getString("author") ?? m.author;
      });
	runApp(
		ChangeNotifierProvider<LocalModel>(
			create: (_) => LocalModel.instance,
			child: const MyApp(),
		)
	);
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			theme: ThemeData(
				colorScheme: ColorScheme.fromSwatch().copyWith(
					primary: const Color.fromARGB(255, 98, 85, 115),
					secondary: const Color.fromARGB(255, 146, 119, 68),
				)
			),
			title: 'Endurance',
			debugShowCheckedModeBanner: false,
			darkTheme: ThemeData.dark(),
			home: const LandingPage(),
		);
	}
}
