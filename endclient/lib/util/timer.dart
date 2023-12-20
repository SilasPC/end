import 'dart:async';
import 'package:flutter/material.dart';

class CountingTimer extends StatefulWidget {
  final bool countUp;
  final DateTime target;
  final VoidCallback? onPassed;
  const CountingTimer(
      {this.countUp = false, required this.target, this.onPassed, super.key});

  @override
  State<StatefulWidget> createState() => CountingTimerState();
}

class CountingTimerState extends State<CountingTimer> {
  bool didPassTarget = false;
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
  Widget build(BuildContext context) {
    Duration d = widget.target.difference(now);
    if (!didPassTarget && d.isNegative) {
      didPassTarget = true;
      widget.onPassed?.call();
    }
    bool wasNeg = d.isNegative;
    if (d.isNegative) {
      d = now.difference(widget.target);
    }
    int m = d.inMinutes;
    int s = d.inSeconds % 60;
    String ms = m > 9 ? "$m" : "0$m";
    String ss = s > 9 ? "$s" : "0$s";
    String fmt = wasNeg ^ widget.countUp ? "-$ms:$ss" : "$ms:$ss";
    return Text(fmt);
  }
}
