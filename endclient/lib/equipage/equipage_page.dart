import 'dart:async';

import 'package:esys_client/consts.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
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
          msg = "Exam attendance before ${unixHMS(time + COOL_TIME)}";
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
    // UI: new equipage page
    context.watch<LocalModel>();
    checkStatusUpdate();
    var (bar, fab) = bottomInfo();
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: fab,
      bottomNavigationBar: bar,
      appBar: AppBar(),
      body: Card(
        child: EquipageTile(widget.equipage),
      ),
    );
  }

  (Widget?, Widget?) bottomInfo() {
    String text;
    DateTime? target;
    switch (widget.equipage.status) {
      case EquipageStatus.COOLING:
        text = "Cooldown";
        if (widget.equipage.currentLoopData?.arrival case int arrival) {
          target = fromUNIX(arrival + COOL_TIME);
        }
      case EquipageStatus.RESTING:
        text = "Resting";
        if (widget.equipage.currentLoopData?.expDeparture case int expDep) {
          target = fromUNIX(expDep);
        }
      default:
        return (null, null);
    }
    return (
      BottomAppBar(
        child: Text(text),
      ),
      target == null ? null : CountDownThing(target: target)
    );
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
            unixDifToMS(dif),
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
