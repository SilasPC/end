
import 'package:flutter/widgets.dart';

const double splashRadius = 16;
const Color primaryColor = Color.fromARGB(255, 98, 85, 115);
const Color secondaryColor = Color.fromARGB(255, 146, 119, 68);
const Color black20 = Color.fromARGB(255, 22, 20, 22);
const Color black27 = Color.fromARGB(255, 29, 27, 29);
const Color black40 = Color.fromARGB(255, 42, 40, 42);
const Color black90 = Color.fromARGB(255, 92, 90, 92);

const BoxDecoration backgroundGradient =
	BoxDecoration(
		gradient: LinearGradient(
			begin: Alignment.topCenter,
			end: Alignment.bottomCenter,
			stops: [
				0.1,
				0.5,
				0.9,
			],
			colors: [
				Color.fromARGB(255, 14, 14, 14),
				Color.fromARGB(255, 62, 58, 62),
				Color.fromARGB(255, 14, 14, 14),
			]
		)
	);
