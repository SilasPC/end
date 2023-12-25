import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/app_bars/event_side_bar.dart';
import 'package:esys_client/v2/app_bars/exam_gate_toolbar.dart';
import 'package:esys_client/v2/app_bars/nav_side_bar.dart';
import 'package:esys_client/v2/app_bars/top_bar.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:esys_client/v2/views/exam_gate/exam_data_card.dart';
import 'package:esys_client/v2/views/exam_gate/loop_card.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExamGateView extends StatefulWidget {
  const ExamGateView({super.key});

  @override
  State<ExamGateView> createState() => _ExamGateViewState();
}

class _ExamGateViewState extends State<ExamGateView> {
  final Key _dataCardKey = GlobalKey();
  Equipage? equipage;

  Future<void> submit(VetData data, bool passed, {bool retire = false}) async {
    if (equipage case Equipage equipage) {
      LocalModel model = context.read();
      final author = context.read<IdentityService>().author;
      data.passed = passed;
      int now = nowUNIX();
      model.addSync([
        ExamEvent(author, now, equipage.eid, data, equipage.currentLoop),
        if (retire && !equipage.isFinalLoop)
          RetireEvent(author, now + 1, equipage.eid)
      ]);
      setState(() {
        this.equipage = null;
        data = VetData.empty();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var ui = context.watch<UI>();
      var showList = constraints.maxWidth > 650;
      var showInfo = constraints.maxWidth > 900;
      return Scaffold(
          endDrawer: EventSidebar(),
          appBar: TopBar(),
          drawerEnableOpenDragGesture: false,
          drawer: NavSidebar.fromContext(context),
          bottomNavigationBar: showInfo
              ? null
              : ExamGateToolbar(
                  selectorEnabled: true,
                  equipage: equipage,
                  onChange: (eq) {
                    setState(() {
                      equipage = eq;
                    });
                  },
                ),
          body: !ui.narrow
              ? wideBody(showList, showInfo)
              : Card(
                  child: ExamDataCard(key: _dataCardKey, submit: submit),
                ));
    });
  }

  Widget wideBody(bool showList, bool showInfo) {
    return Row(children: [
      if (showList)
        SizedBox(
          width: 300,
          child: EquipagesCard(
            builder: (context, self, eq, color) {
              if (eq == equipage) {
                return EquipageTile(
                  eq,
                  onTap: () => self.onTap!(eq),
                  color: Theme.of(context)
                      .colorScheme
                      .secondary, //Color.fromARGB(255, 78, 137, 80),
                  trailing: const [Icon(Icons.chevron_right)],
                );
              }
              return EquipagesCard.withChevrons(context, self, eq, color);
            },
            onTap: (eq) => setState(() {
              equipage = eq;
            }),
            filter: (e) => e.status == EquipageStatus.EXAM || e == equipage,
            emptyLabel: "None ready for examination",
          ),
        ),
      if (showInfo)
        SizedBox(
          width: 400,
          child: ExamDataCard(
            key: _dataCardKey,
            submit: submit,
          ),
        )
      else
        Expanded(child: ExamDataCard(key: _dataCardKey, submit: submit)),
      if (showInfo)
        Expanded(
          child: Card(
            child: Column(
              children: [
                ...cardHeader("Equipage info"),
                if (equipage case Equipage equipage) ...[
                  EquipageTile(equipage),
                  ListTile(
                    title: const Text("Loop"),
                    trailing: Text(
                        "${equipage.currentLoopOneIndexed ?? "-"}/${equipage.category.loops.length}"),
                  ),
                  Expanded(
                    child: ListView(
                      children: loopCards(equipage),
                    ),
                  )
                ] else
                  emptyListText("Select an equipage")
              ],
            ),
          ),
        )
    ]);
  }
}

List<Widget> loopCards(Equipage equipage) {
  var lps = equipage.loops;
  int? cl = equipage.currentLoop;
  if (cl == null) return [];
  var widgets = [
    for (int l = cl; l >= 0; l--)
      LoopCard(loopNr: l + 1, loopData: lps[l], isFinish: l == lps.length),
    if (equipage.preExam case VetData vd) LoopCard.preExam(vd)
  ];
  if (widgets.isEmpty) {
    widgets.add(
      emptyListText("Loop data unavailable"),
    );
  }
  return widgets;
}
