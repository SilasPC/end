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
    return Scaffold(
      bottomNavigationBar: bottomBar(),
      appBar: AppBar(),
      body: Card(
        child: EquipageTile(widget.equipage),
      ),
    );
  }

  Widget? bottomBar() {
    // UI: more info
    return Container(
      height: 200,
      decoration: BoxDecoration(
          gradient: backgroundGradient.gradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
              width: 150,
              height: 150,
              child: Center(child: CircularProgressIndicator(value: 0.8))),
          Text("hello"),
        ],
      ),
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
