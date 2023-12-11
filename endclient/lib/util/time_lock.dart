
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:common/util.dart';

class TimeLock extends StatelessWidget {
	final void Function(DateTime) onChanged;
	final DateTime? time;

	const TimeLock({super.key, required this.time, required this.onChanged});

	@override
	Widget build(BuildContext context) =>
		switch (time) {
			null => IconButton(
				icon: Icon(Icons.timer, color: Theme.of(context).primaryColor),
				onPressed: () => onChanged(DateTime.now()),
			),
			var time => GestureDetector(
				child: Text(toHMS(time)),
				onTap: () {
					showHMSPicker(
						context,
						time,
						onChanged
					);
				}
			)
		};
}
