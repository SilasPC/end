
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

Widget labelIconButton(String text, IconData icon, {VoidCallback? onPressed}) =>
	ElevatedButton(
		style: ElevatedButton.styleFrom(backgroundColor: Colors.black38.withAlpha(200)),
		onPressed: onPressed,
		child: Row(
			mainAxisSize: MainAxisSize.min,
			children: [
				Text(text),
				const SizedBox(width: 6),
				Icon(icon),
			],
		),
	);

Widget emptyListText(String label) =>
	Container(
		alignment: Alignment.topCenter,
		padding: const EdgeInsets.only(top: 16),
		child: Text(
			label,
			style: const TextStyle(
				fontSize: 16,
				fontStyle: FontStyle.italic,
			)
		),
	);
