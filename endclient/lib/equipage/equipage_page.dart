import 'dart:async';
import 'package:esys_client/consts.dart';
import 'package:esys_client/util/util.dart';
import 'package:esys_client/v2/app_bars/top_bar.dart';
import 'package:esys_client/v2/dashboard/component/equipage_card.dart';
import 'package:esys_client/v2/views/exam_gate/loop_card.dart';
import 'package:flutter/material.dart';
import 'package:locally/locally.dart';
import 'package:provider/provider.dart';
import 'package:common/consts.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';

import '../services/settings.dart';

import '../services/local_model.dart';

class EquipagePage extends StatefulWidget {
  final Equipage equipage;

  const EquipagePage(this.equipage, {super.key});
  @override
  EquipagePageState createState() => EquipagePageState();
}

class EquipagePageState extends State<EquipagePage> {
  late EquipageStatus _prevStatus;

  @override
  void initState() {
    super.initState();
    _prevStatus = widget.equipage.status;
  }

  void checkStatusUpdate() {
    if (_prevStatus != widget.equipage.status) {
      _prevStatus = widget.equipage.status;
      String? msg;
      switch (widget.equipage.status) {
        case EquipageStatus.COOLING:
          var time = widget.equipage.currentLoopData?.arrival;
          if (time == null) break;
          msg = "Exam attendance before ${unixHMS(time + COOL_TIME.inSeconds)}";
          break;
        case EquipageStatus.RESTING:
          var time = widget.equipage.currentLoopData?.expDeparture;
          if (time == null) break;
          msg = "Departure time ${unixHMS(time)}";
          break;
        case EquipageStatus.FINISHED:
          var pos = (widget.equipage.category.equipages.toList()
                    ..sort(Equipage.byRank))
                  .indexOf(widget.equipage) +
              1;
          msg = "Finished as #$pos";
          break;
        default:
      }
      if (msg != null && context.read<Settings>().sendNotifs) {
        int loop = (widget.equipage.currentLoop ?? -1) + 1;
        Locally(
          context: context,
          pageRoute: MaterialPageRoute(builder: (_) => widget),
          payload: "wutisdis",
          appIcon: "mipmap/ic_launcher",
        ).show(title: "Status loop $loop", message: msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocalModel>();
    checkStatusUpdate();
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        appBar: TopBar(),
        body: Stack(
          children: [
            EquipageInfoCard(widget.equipage),
            if (infoSheet() case Widget w) w,
          ],
        ));
  }

  Widget sheet(DateTime target, Duration high, Duration low) {
    return LayoutBuilder(builder: (context, constraints) {
      final minSize = kToolbarHeight / constraints.maxHeight;
      const maxSize = 0.4;
      return DraggableScrollableSheet(
        initialChildSize: minSize,
        minChildSize: minSize,
        maxChildSize: maxSize,
        snap: true,
        builder: (context, ctrl) => Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: Theme.of(context).colorScheme.surface),
            child: SingleChildScrollView(
                controller: ctrl,
                child: Column(
                  children: [
                    const DragHandle(),
                    CountdownTimer(
                      size: 0.5 * constraints.maxWidth,
                      target: target,
                      low: low,
                      high: high,
                    ),
                    Text(widget.equipage.status.name,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ))),
      );
    });
  }

  Widget? infoSheet() {
    switch (widget.equipage.status) {
      case EquipageStatus.COOLING:
        if (widget.equipage.currentLoopData?.arrival case int arrival) {
          var target = fromUNIX(arrival + COOL_TIME.inSeconds);
          return sheet(target, COOL_TIME, Duration(minutes: 3));
        }
        break;
      case EquipageStatus.RESTING:
        if (widget.equipage.currentLoopData?.expDeparture case int expDep) {
          var target = fromUNIX(expDep);
          return sheet(target, REST_TIME, Duration(minutes: 0));
        }
        break;
      default:
    }
  }

  List<Widget> loopCards() {
    var lps = widget.equipage.loops;
    int? cl = widget.equipage.currentLoop;
    if (cl == null) return [];
    return [
      for (int l = cl; l >= 0; l--)
        LoopCard(loopNr: l + 1, loopData: lps[l], isFinish: l == lps.length),
      if (widget.equipage.preExam case VetData vd)
        Card(
          child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    border: Border.all(
                      color: Colors.black54,
                      width: 0.3,
                    ),
                  ),
                  height: 30,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("PRE-EXAM"),
                    ],
                  )),
              LoopCard.remarksList(vd.remarks())
            ],
          ),
        )
    ];
  }
}

class CountDownThing extends StatefulWidget {
  final DateTime target;

  const CountDownThing({
    super.key,
    required this.target,
  });

  @override
  State<CountDownThing> createState() => _CountDownThingState();
}

class _CountDownThingState extends State<CountDownThing> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    int dif = widget.target.difference(DateTime.now()).inSeconds;
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
              child: Text(
            formatSeconds(dif),
            style: TextStyle(fontSize: 20),
          )),
          CircularProgressIndicator(
            color: Colors.blue,
            backgroundColor: Colors.green,
            value: 1 - (dif / 20).clamp(0, 1),
            strokeCap: StrokeCap.round,
            strokeAlign: -1,
            strokeWidth: 12,
          ),
        ],
      ),
    );
  }
}
