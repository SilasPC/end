
import 'package:common/util.dart';
import 'package:esys_client/util/numpad.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class HmsPicker extends StatefulWidget {

	final DateTime dateTime;
	final Function(DateTime) onAccept;

	const HmsPicker({super.key, required this.dateTime, required this.onAccept});

	@override
	HmsPickerState createState() => HmsPickerState(dateTime, onAccept);

}

class HmsPickerState extends State<HmsPicker> {

	int h,m,s;
	void Function(DateTime) onAccept;

	HmsPickerState(DateTime dt, this.onAccept):
		h = dt.hour,
		m = dt.minute,
		s = dt.second;

	@override
	Widget build(BuildContext context) =>
		Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				NumberPicker(
					value: h,
					minValue: 0,
					maxValue: 23,
					zeroPad: true,
					infiniteLoop: true,
					onChanged: (n) => setState(() { h = n; }),
				),
				NumberPicker(
					value: m,
					minValue: 0,
					maxValue: 59,
					zeroPad: true,
					infiniteLoop: true,
					onChanged: (n) => setState(() { m = n; }),
				),
				NumberPicker(
					value: s,
					minValue: 0,
					maxValue: 59,
					zeroPad: true,
					infiniteLoop: true,
					onChanged: (n) => setState(() { s = n; }),
				),
				Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						ElevatedButton(
							child: Text("OK"),
							onPressed: () => onAccept(fromHMS(h,m,s)),
						)
					],
				)
			]
		);

}
