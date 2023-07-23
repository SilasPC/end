
import 'package:flutter/material.dart';

Widget cardHeader(String text) =>
	Container(
		padding: const EdgeInsets.only(top: 7),
		child: Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [Text(text, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold))],
		)
	);
