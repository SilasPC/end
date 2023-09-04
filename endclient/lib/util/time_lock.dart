
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
					showDialog(
						context: context,
						builder: (context) {
							return Dialog(
								child: HmsPicker(
									dateTime: time!,
									onAccept: (dt) {
										Navigator.pop(context);
										onChanged(dt);
									},
								)
							);
						}
					);
				}
			);
}
