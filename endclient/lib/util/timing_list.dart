
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:common/util.dart';
import 'hms_picker.dart';

class TimingList extends StatelessWidget {

	final List<DateTime> timers;
	final void Function(int) onRemoveTimer;
	final void Function(int, int) onReorder;
	final void Function(int, DateTime) onReorderRow;
	final List<Widget> children;
	//final Widget Function()? restBuilder;
	final double height;

	const TimingList({super.key, required this.timers, required this.onRemoveTimer, required this.onReorder, required this.onReorderRow, required this.height, /*this.restBuilder,*/ required this.children});

	@override
	Widget build(BuildContext context) =>
		SingleChildScrollView(
			child: SizedBox(
				height: max(children.length, timers.length) * height,
				child: Row(
					children: [
						Expanded(
							child: ReorderableListView(
								// PERF: would be faster, but causes UI glitch
								// itemExtent: height,
								onReorder: onReorder,
								children: children,
							),
						),
						SizedBox(
							width: 80,
							child: ListView(
								children: [
									for (int i = 0; i < timers.length; i++)
									Container(
										padding: const EdgeInsets.all(8),
										height: height,
										alignment: Alignment.center,
										child: GestureDetector(
											onLongPress: () => onRemoveTimer(i),
											onTap: () {
												showDialog(
													context: context,
													builder: (context) {
														return Dialog(
															child: HmsPicker(
																dateTime: timers[i],
																onAccept: (dt) {
																	Navigator.pop(context);
																	onReorderRow(i, dt);
																},
															)
														);
													}
												);
											},
											child: i == 0
												? Text(toHMS(timers[i]))
												: Text("${toHMS(timers[i])}\n(${unixDifToMS((timers[i].millisecondsSinceEpoch-timers[i-1].millisecondsSinceEpoch)~/1000, true)})")
										),
									),
								],
							),
						),
					],
				)
			)
		);
}
