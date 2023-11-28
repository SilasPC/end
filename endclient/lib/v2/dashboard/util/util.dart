
import 'package:flutter/material.dart';

List<Widget> cardHeader(String label) => [
	Container(
		alignment: Alignment.center,
		padding: const EdgeInsets.all(8),
		child: Text(
			label,
			overflow: TextOverflow.ellipsis,
			maxLines: 1,
			style: const TextStyle(
				fontSize: 20
			)
		),
	),
	const Divider(),
];

Widget coloredCardheader(String label) =>
	Container(
		padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
		alignment: Alignment.center,
		decoration: const BoxDecoration(
			borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			color: Colors.black26, // TODO: theme                   ^ read from cardtheme
		),
		child: Text(
			label,
			overflow: TextOverflow.ellipsis,
			maxLines: 1,
			style: const TextStyle(
				fontSize: 20,
			)
		)
	);
