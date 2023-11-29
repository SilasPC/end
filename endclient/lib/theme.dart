// ignore_for_file: prefer_const_constructors

import 'package:esys_client/consts.dart';
import 'package:flutter/material.dart';

(ThemeData, ThemeData) themeData() {

	ColorScheme colorScheme = ColorScheme.fromSwatch(
		primarySwatch: _createMaterialColor(primaryColor),
	).copyWith(
		secondary: secondaryColor,
	);

	ThemeData lightTheme = 
		ThemeData.light().copyWith(
			colorScheme: colorScheme,
			bottomNavigationBarTheme: BottomNavigationBarThemeData(
				backgroundColor: colorScheme.background,
			),
			chipTheme: ChipThemeData(
				showCheckmark: false,
				// backgroundColor: black90,
				selectedColor: colorScheme.secondary,
			),
			switchTheme: SwitchThemeData(
				splashRadius: splashRadius,
			),
			cardTheme: CardTheme(
				color: colorScheme.background,
				margin: const EdgeInsets.all(16),
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(20),
				)
			),
		);

	ThemeData darkTheme = ThemeData.dark().copyWith(
		colorScheme: colorScheme,
		focusColor: black27,
		bottomNavigationBarTheme: BottomNavigationBarThemeData(
			backgroundColor: black27,
		),
		switchTheme: SwitchThemeData(
			splashRadius: splashRadius,
		),
		chipTheme: ChipThemeData(
			showCheckmark: false,
			// backgroundColor: black90,
			selectedColor: colorScheme.secondary,
		),
		cardTheme: CardTheme(
			color: black20,
			margin: const EdgeInsets.all(16),
			shape: RoundedRectangleBorder(
				borderRadius: BorderRadius.circular(20),
			),
		),
	);

	return (lightTheme, darkTheme);

}

// https://gist.github.com/nicky-song/244be04f1dbdba52788017f008477484#file-utils-dart
MaterialColor _createMaterialColor(Color color) {
	List strengths = <double>[.05];
	Map<int, Color> swatch = {};
	final int r = color.red, g = color.green, b = color.blue;

	for (int i = 1; i < 10; i++) {
		strengths.add(0.1 * i);
	}
	for (var strength in strengths) {
		final double ds = 0.5 - strength;
		swatch[(strength * 1000).round()] = Color.fromRGBO(
			r + ((ds < 0 ? r : (255 - r)) * ds).round(),
			g + ((ds < 0 ? g : (255 - g)) * ds).round(),
			b + ((ds < 0 ? b : (255 - b)) * ds).round(),
			1,
		);
	}
	return MaterialColor(color.value, swatch);
}
