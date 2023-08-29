
import 'package:flutter/material.dart';

Widget cardHeader(BuildContext context, String text, {Color? color}) =>
	Container(
		padding: const EdgeInsets.symmetric(vertical: 7),
		decoration: BoxDecoration(
			// clips contents????
			// borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
			color: color,
			border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))
		),
		child: Column(
			crossAxisAlignment: CrossAxisAlignment.stretch,
			children: [
				Text(text,
					textAlign: TextAlign.center,
					maxLines: 1,
					style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
					overflow: TextOverflow.fade,
				),
			]
		),
	);
