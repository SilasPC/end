
import 'package:common/util.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class HmsPicker extends StatefulWidget {

	final DateTime dateTime;
	final void Function(DateTime) onAccept;

	const HmsPicker({super.key, required this.dateTime, required this.onAccept});

	@override
	HmsPickerState createState() => HmsPickerState();

}

class HmsPickerState extends State<HmsPicker> {

	late int h,m,s;
	
	@override
	void initState() {
		super.initState();
		h = widget.dateTime.hour;
		m = widget.dateTime.minute;
		s = widget.dateTime.second;
	}

	@override
	Widget build(BuildContext context) =>
		SizedBox(
			height: 200,
			child: Row(
				mainAxisSize: MainAxisSize.min,
				mainAxisAlignment: MainAxisAlignment.center,
				crossAxisAlignment: CrossAxisAlignment.center,
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
					ElevatedButton(
						child: const Text("OK"),
						onPressed: () => widget.onAccept(fromHMS(h,m,s)),
					),
				]
			)
		);

}
