
import 'package:esys_client/util/numpad.dart';
import 'package:flutter/material.dart';

class IntPicker extends StatefulWidget {

	final Function(int n) onAccept;

	const IntPicker({super.key, required this.onAccept});

	@override
	IntPickerState createState() => IntPickerState();

}

class IntPickerState extends State<IntPicker> {

	String n = "";

	@override
	Widget build(BuildContext context) => Column(
		mainAxisSize: MainAxisSize.min,
		children: [
			Padding(
				padding: const EdgeInsets.all(10),
				child: Row(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [Text(n, style: const TextStyle(fontSize: 30),)]
				)
			),
			Expanded(
				child: Numpad(
					onChange: (val) {
						setState(() {
							n = val;
						});
					},
					onAccept: (val) {
						int? n = int.tryParse(val);
						if (n != null) {
							widget.onAccept(n);
						}
					}
				)
			)
		],
	);

}
