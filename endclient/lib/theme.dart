
import 'package:esys_client/consts.dart';
import 'package:flutter/material.dart';

(ThemeData, ThemeData) themeData() {

	var swatch = _createMaterialColor(primaryColor);

	ColorScheme colorScheme = ColorScheme.fromSwatch(
		primarySwatch: swatch,
		backgroundColor: swatch.shade50,
	).copyWith(
		secondary: secondaryColor,
	);

	ThemeData lightTheme = ThemeData.light().copyWith(
		colorScheme: colorScheme,
		focusColor: null,
		bottomNavigationBarTheme: BottomNavigationBarThemeData(
			backgroundColor: colorScheme.background,
		),
		chipTheme: ChipThemeData(
			showCheckmark: false,
			selectedColor: colorScheme.secondary,
		),
		switchTheme: SwitchThemeData(
			splashRadius: splashRadius,
			thumbColor: MaterialStateProperty.all(colorScheme.inversePrimary),
			trackOutlineColor: MaterialStateProperty.all(colorScheme.primary),
			trackColor: MaterialStateProperty.resolveWith((set) {
				if (set.contains(MaterialState.selected)) {
					return colorScheme.primary;
				}
				return colorScheme.background;
			})
		),
		elevatedButtonTheme: const ElevatedButtonThemeData(
			/* style: ElevatedButton.styleFrom(
				backgroundColor: colorScheme.surface,
			) */
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
		// UI: textTheme: Typography.whiteHelsinki,
		bottomNavigationBarTheme: const BottomNavigationBarThemeData(
			backgroundColor: black27,
		),
		chipTheme: ChipThemeData(
			showCheckmark: false,
			selectedColor: colorScheme.secondary,
		),
		switchTheme: SwitchThemeData(
			splashRadius: splashRadius,
			thumbColor: MaterialStateProperty.all(colorScheme.inversePrimary),
			trackOutlineColor: MaterialStateProperty.all(colorScheme.primary),
			trackColor: MaterialStateProperty.resolveWith((set) {
				if (set.contains(MaterialState.selected)) {
					return colorScheme.primary;
				}
				return black27;
			})
		),
		elevatedButtonTheme: ElevatedButtonThemeData(
			style: ElevatedButton.styleFrom(
				backgroundColor: Colors.black26,
				/* textStyle: TextStyle(
					color: colorScheme.tertiary,
				) */
			)
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
