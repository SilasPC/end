import 'dart:math';
import 'package:esys_client/util/input/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:common/util.dart';

class TimingList extends StatelessWidget {
  final List<DateTime> timers;
  final void Function(int) onRemoveTimer;
  final void Function(int) onAddTimer;
  final void Function(int, int) onReorder;
  final void Function(int, DateTime) onReorderRow;
  final List<Widget> children;
  final double height;

  const TimingList(
      {super.key,
      required this.timers,
      required this.onRemoveTimer,
      required this.onReorder,
      required this.onReorderRow,
      required this.onAddTimer,
      required this.height,
      /*this.restBuilder,*/ required this.children});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: SizedBox(
          height: max(children.length, timers.length) * height,
          child: Row(
            children: [
              Expanded(
                child: ReorderableListView(
                  // IGNORED: PERF: would be faster, but causes UI glitch
                  // itemExtent: height,
                  onReorder: onReorder,
                  children: children,
                ),
              ),
              SizedBox(
                width: 120,
                child: ListView(
                  children: [
                    for (int i = 0; i < timers.length; i++)
                      Container(
                          height: height,
                          alignment: Alignment.center,
                          child: InputChip(
                            label: Text(toHMS(timers[i])),
                            onPressed: () {
                              showHMSPicker(context, timers[i],
                                  (dt) => onReorderRow(i, dt));
                            },
                            onDeleted: () {
                              onRemoveTimer(i);
                            },
                          )),
                    for (int i = timers.length; i < children.length; i++)
                      Container(
                          height: height,
                          alignment: Alignment.center,
                          child: ActionChip(
                            label: Icon(Icons.alarm_add),
                            onPressed: () {
                              onAddTimer(i);
                            },
                          ))
                  ],
                ),
              ),
            ],
          )));
}
