
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:common/util.dart';

import 'hms_picker.dart';

class TimeLock extends StatelessWidget {
	final void Function(DateTime) onChanged;
	final DateTime? time;

	const TimeLock({super.key, required this.time, required this.onChanged});

	@override
	Widget build(BuildContext context) =>
		time == null
			? IconButton(
				icon: const Icon(Icons.timer, color: Colors.green),
				onPressed: () => onChanged(DateTime.now()),
			)
			: GestureDetector(
				child: Text(toHMS(time!)),
				onTap: () {
					showHMSPicker(
						context,
						time!,
						onChanged
					);
				}
			);
}
