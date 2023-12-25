import 'dart:async';

import 'package:common/util/unix.dart';
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

class DragHandle extends StatelessWidget {
  const DragHandle({
    super.key,
  });

  static const double height = 2 * 22 + 4;

  @override
  Widget build(BuildContext context) {
    // this is according to material 3 specs
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(102),
      ),
      height: 4,
      width: 32,
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final double size;
  final DateTime target;
  final Duration low, high;

  const CountdownTimer(
      {super.key,
      this.size = 70,
      required this.target,
      required this.low,
      required this.high});

  @override
  State<CountdownTimer> createState() => CountdownTimerState();
}

class CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  int left = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    left = widget.target.difference(DateTime.now()).inSeconds;
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        left = widget.target.difference(DateTime.now()).inSeconds;
      });
    });
  }

  static const redBg = const Color.fromARGB(255, 121, 17, 10);
  static const blueBg = Color.fromARGB(255, 11, 79, 134);

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    double val;
    if (left < widget.low.inSeconds) {
      bg = redBg;
      fg = Colors.red;
      val = (left / widget.low.inSeconds).clamp(0.0, 1.0);
    } else {
      var trn = ((left - widget.low.inSeconds) / 5).clamp(0.0, 1.0);
      bg = Color.lerp(Colors.red, blueBg, trn)!;
      fg = Colors.blue;
      val = ((left - widget.low.inSeconds) /
              (widget.high.inSeconds - widget.low.inSeconds))
          .clamp(0.0, 1.0);
    }
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(widget.size),
                boxShadow: kElevationToShadow[3]!),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: FittedBox(
              child: Text(
                formatSeconds(left),
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          CircularProgressIndicator(
            color: fg,
            backgroundColor: bg,
            value: val,
            strokeCap: StrokeCap.round,
            strokeWidth: 15,
            strokeAlign: -2,
          ),
        ],
      ),
    );
  }
}
