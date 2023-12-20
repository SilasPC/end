import 'package:flutter/material.dart';

class TimerList {
  List<DateTime> times = [];

  int get length => times.length;
  bool get isEmpty => times.isEmpty;
  bool get isNotEmpty => times.isNotEmpty;

  void addNow() {
    DateTime now = DateTime.now();
    now = now.subtract(Duration(milliseconds: now.millisecond));
    if (times.isNotEmpty) {
      int milliMin = times.last.millisecondsSinceEpoch + 1000;
      if (now.millisecondsSinceEpoch < milliMin) {
        now = DateTime.fromMillisecondsSinceEpoch(milliMin);
      }
    }
    times.add(now);
  }

  DateTime operator [](int i) => times[i];
}
