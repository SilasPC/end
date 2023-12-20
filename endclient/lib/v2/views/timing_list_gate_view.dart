import 'dart:math';

import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/timing_list.dart';
import 'package:esys_client/util/util.dart';
import 'package:esys_client/v2/app_bars/side_bar.dart';
import 'package:esys_client/v2/app_bars/timing_gate_toolbar.dart';
import 'package:esys_client/v2/app_bars/top_bar.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:common/models/glob.dart';
import 'package:wakelock/wakelock.dart';

class TimingListGateView extends StatefulWidget {
  final Future<void> Function(Iterable<(Equipage, DateTime)>) submit;
  final Predicate<Equipage> predicate;
  const TimingListGateView({
    super.key,
    required this.predicate,
    required this.submit,
  });

  @override
  State<TimingListGateView> createState() => _TimingListGateViewState();
}

class _TimingListGateViewState extends State<TimingListGateView> {
  bool narrow = false;
  List<Equipage> equipages = [];
  TimerList timerList = TimerList();

  @override
  void dispose() {
    super.dispose();
    Wakelock.disable().catchError((_) {});
  }

  void addTime() {
    setState(() {
      timerList.addNow();
    });
  }

  bool get submitable => timerList.isNotEmpty && equipages.isNotEmpty;
  Future<void> submit() {
    int l = min(timerList.length, equipages.length);
    var data = [for (int i = 0; i < l; i++) (equipages[i], timerList.times[i])];
    var submission = widget.submit(data);
    setState(() {
      equipages = [];
      timerList.times.clear();
    });
    return submission;
  }

  void refresh() {
    setState(() {
      for (int i = equipages.length - 1; i >= 0; i--) {
        if (widget.predicate(equipages[i])) continue;
        equipages.removeAt(i);
        if (i < timerList.length) {
          timerList.times.removeAt(i);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    narrow = MediaQuery.sizeOf(context).width < 550;
    if (context.read<Settings>().useWakeLock) {
      Wakelock.enable().catchError((_) {});
    }
    var model = context.watch<LocalModel>();

    Set<Equipage> newEquipages =
        model.model.equipages.values.where(widget.predicate).toSet();
    Set<Equipage> oldEquipages = equipages.toSet();
    equipages.addAll(newEquipages.difference(oldEquipages));
  }

  final Key _timingListKey = UniqueKey();
  Widget timingList() => TimingList(
          key: _timingListKey,
          timers: timerList.times,
          onRemoveTimer: (i) => setState(() => timerList.times.removeAt(i)),
          onReorder: (i, j) => setState(() => reorder(i, j, equipages)),
          onReorderRow: (i, dt) => setState(() {
                timerList.times.removeAt(i);
                int j = timerList.times.indexWhere((t) => dt.isBefore(t));
                if (j == -1) j = timerList.times.length;
                timerList.times.insert(j, dt);
                swap(i, j, equipages);
              }),
          height: EquipageTile.height,
          children: [
            for (Equipage eq in equipages)
              Padding(
                key: ValueKey("EID${eq.eid}"),
                padding: const EdgeInsets.only(right: 24),
                child: EquipageTile(
                  eq,
                  onTap: () {
                    if (timerList.length < equipages.length) {
                      setState(() {
                        swap(
                            equipages.indexOf(eq), timerList.length, equipages);
                        timerList.addNow();
                      });
                    }
                  },
                ),
              )
          ]);

  @override
  Widget build(BuildContext context) {
    var ui = context.watch<UI>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TopBar(),
      floatingActionButtonLocation: narrow
          ? FloatingActionButtonLocation.centerDocked
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: fab(),
      drawerEnableOpenDragGesture: false,
      drawer: SideBar.fromUI(ui),
      bottomNavigationBar: !narrow
          ? null
          : TimingGateToolbar(
              selectorSheetEnabled: narrow,
              onPressed: submitable ? submit : null,
              onRefresh: refresh,
              equipages: equipages,
              onAdd: (eq) => setState(() {
                equipages.add(eq);
              }),
            ),
      body: narrow
          ? Card(
              child: Column(
              children: [
                ...cardHeader("Timings"),
                Expanded(child: timingList())
              ],
            ))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: EquipagesCard(
                    builder: (context, self, eq, color) {
                      var inList = equipages.contains(eq);
                      return EquipageTile(
                        eq,
                        trailing: !inList
                            ? const [Icon(Icons.chevron_right)]
                            : const [Icon(null)],
                        onTap: () {
                          if (!inList) {
                            setState(() {
                              equipages.add(eq);
                            });
                          }
                        },
                      );
                    },
                    filter: (eq) => widget.predicate(eq),
                  ),
                ),
                Expanded(
                  child: Card(
                      child: Column(
                    children: [
                      ...cardHeader("Timings"),
                      Expanded(child: timingList())
                    ],
                  )),
                ),
              ],
            ),
    );
  }

  FloatingActionButton fab() {
    if (narrow) {
      return FloatingActionButton(
        onPressed: addTime,
        child: Icon(Icons.add_alarm),
      );
    }
    return FloatingActionButton.large(
      onPressed: addTime,
      child: Icon(Icons.add_alarm),
    );
  }
}
