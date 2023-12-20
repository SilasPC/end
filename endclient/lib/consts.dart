import 'package:flutter/widgets.dart';

const double splashRadius = 16;
const Color primaryColor = Color.fromARGB(255, 179, 12, 40);
const Color secondaryColor = Color.fromARGB(255, 20, 61, 138);
const Color black20 = Color.fromARGB(255, 22, 20, 22);
const Color black27 = Color.fromARGB(255, 29, 27, 29);
const Color black40 = Color.fromARGB(255, 42, 40, 42);
const Color black90 = Color.fromARGB(255, 92, 90, 92);

const BoxDecoration backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [
      0.1,
      0.5,
      0.9,
    ],
        colors: [
      Color.fromARGB(255, 14, 14, 24),
      Color.fromARGB(255, 62, 58, 72),
      Color.fromARGB(255, 14, 14, 24),
    ]));
