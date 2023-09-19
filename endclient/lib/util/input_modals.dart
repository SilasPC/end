
import 'package:animations/animations.dart';
import 'package:esys_client/util/int_picker.dart';
import 'package:flutter/material.dart';

import 'hms_picker.dart';

void showInputDialog(
	BuildContext context,
	String label,
	Function(String s) onAccept,
) {
	var ctrl = TextEditingController();
	showModal(
		context: context,
		builder: (context) => Dialog(
			child: Padding(
				padding: const EdgeInsets.all(10),
				child: Row(
					children: [
						Expanded(
							child: TextField(
								maxLines: null,
								controller: ctrl,
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
						IconButton(
							icon: const Icon(Icons.send),
							onPressed: () {
								Navigator.pop(context);
								onAccept(ctrl.text);
							},
						),
					]
				)
			)
		)
	);
}
void showHMSPicker(BuildContext context, DateTime time, void Function(DateTime) onAccept) {
	showDialog(
		context: context,
		builder: (context) {
			return Dialog(
				child: HmsPicker(
					dateTime: time,
					onAccept: (dt) {
						Navigator.of(context).pop();
						onAccept(dt);
					}
				)
			);
		}
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
