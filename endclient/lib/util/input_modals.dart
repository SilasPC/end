
import 'package:esys_client/util/int_picker.dart';
import 'package:flutter/material.dart';

void showInputModal(
	BuildContext context,
	String label,
	Function(String s) onAccept
) {
	// UI: these are hidden behind keyboard
	showModalBottomSheet(
		context: context,
		builder: (context) => Padding(
			padding: const EdgeInsets.all(10),
			child: TextField(
				decoration: InputDecoration(
					border: const OutlineInputBorder(),
					hintText: label,
				),
				autofocus: true,
				onSubmitted: (str) {
					Navigator.pop(context);
					onAccept(str);
				},
			),
		),
	);
}

void showChoicesModal(
	BuildContext context,
	List<String> options,
	Function(String s) onAccept
) {
	showModalBottomSheet(
		context: context,
		builder: (context) => Padding(
			padding: const EdgeInsets.all(10),
			child: ListView(
				children: [
					for (String option in options)
					ListTile(
						title: Text(option),
						onTap: () {
							Navigator.pop(context);
							onAccept(option);
						},
					)
				],
			)
		),
	);
}

void showIntPicker(
	BuildContext context,
	Function(int n) onAccept,
) {
	showModalBottomSheet(
		context: context,
		builder: (context) => IntPicker(onAccept: onAccept)
	);
}
