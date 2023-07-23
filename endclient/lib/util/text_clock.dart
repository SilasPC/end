
import 'dart:async';

import 'package:common/util.dart';
import 'package:flutter/material.dart';

class TextClock extends StatefulWidget {

	final Widget Function(String) builder;

	factory TextClock.withPrefix(String prefix) =>
		TextClock.withBuilder((hms) => Text(prefix + hms));
	const TextClock.withBuilder(this.builder, {super.key});
	TextClock({super.key}):
		builder = ((String s) => Text(s));

	@override
	State<StatefulWidget> createState() => TextClockState();
}

class TextClockState extends State<TextClock> {

	DateTime now = DateTime.now();
	Timer? timer;

	@override
	void initState() {
		super.initState();
		timer = Timer.periodic(const Duration(seconds: 1), (_) {
			setState(() {
				now = DateTime.now();
			});
		});
	}

	@override
	void dispose() {
		timer?.cancel();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) =>
		widget.builder(toHMS(now));

}
