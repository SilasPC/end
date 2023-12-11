
import 'package:flutter/material.dart';

class Numpad extends StatefulWidget {

	final void Function(String n) onAccept;
	final void Function(String n)? onChange;
	
	const Numpad({this.onChange, required this.onAccept, super.key});

	@override
	State<Numpad> createState() => _NumpadState();
}

class _NumpadState extends State<Numpad> {

	String digits = "";

	Widget buildKey(String x, [VoidCallback? h]) =>
		ElevatedButton(
				style: ElevatedButton.styleFrom(
					shape: const RoundedRectangleBorder(
						borderRadius: BorderRadius.all(Radius.circular(5))
					),
				),
				onPressed: h ?? () =>
					setState(() {
						digits += x;
						widget.onChange?.call(digits);
					}),
				child: Center(
					child: Text(x, style: const TextStyle(fontSize: 24))
				)
			);

	@override
	Widget build(BuildContext context) =>
		GridView.count(
			crossAxisCount: 3,
			crossAxisSpacing: 10,
			mainAxisSpacing: 10,
			childAspectRatio: 2,
			padding: const EdgeInsets.all(10),
			children: [
				for (int i = 1; i <= 9; i++)
					buildKey(i.toString()),
				buildKey("<-",
					() => setState(() {
						if (digits.isNotEmpty) {
							digits = digits.substring(0, digits.length-1);
							widget.onChange?.call(digits);
						}
					})
				),
				buildKey("0"),
				buildKey("OK", () => widget.onAccept(digits)),
			],			
		);
}
