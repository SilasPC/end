
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

Widget coloredCardheader(BuildContext context, String label) {
	var shape = CardTheme.of(context).shape;
	BorderRadius? borderRadius;
	if (shape case RoundedRectangleBorder(borderRadius: BorderRadius(:var topLeft, :var topRight)) when topLeft == topRight) {
		borderRadius = BorderRadius.vertical(
			top: topLeft
		);
	}
	return Container(
		padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
		alignment: Alignment.center,
		decoration: BoxDecoration(
			borderRadius: borderRadius,
			color: Colors.black26, // TODO: theme
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
}
