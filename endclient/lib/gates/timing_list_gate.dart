

import 'dart:math';

import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/equipage_selector_drawer.dart';
import 'package:esys_client/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:common/models/glob.dart';
import 'package:wakelock/wakelock.dart';

import '../services/local_model.dart';
import '../util/submit_button.dart';
import '../util/text_clock.dart';
import '../util/timing_list.dart';
import 'gate_controller.dart';

class TimingListGate extends StatefulWidget {

	final Widget title;
	final Future<void> Function(List<Equipage> equipages, List<DateTime> times) submit;
	final Predicate<Equipage> predicate;
	final GateController? controller;
	const TimingListGate({
		super.key,
		required this.title,
		required this.predicate,
		required this.submit,
		this.controller,
	});

	@override
	State<TimingListGate> createState() => _TimingListGateState();
}

class _TimingListGateState extends State<TimingListGate> implements GateState {

	List<Equipage> equipages = [];
	TimerList timerList = TimerList();

	@override
	void dispose() {
		super.dispose();
		Wakelock.disable();
	}
	
	@override
	void initState() {
		super.initState();
		widget.controller?.state = this;
	}

	@override
	void refresh() {
		if (!mounted) return;
		setState(() {
			for (int i = equipages.length; i >= 0; i--) {
				if (widget.predicate(equipages[i])) continue;
				equipages.removeAt(i);
				if (i < timerList.length) {
					timerList.times.removeAt(i);
				}
			}
		});
	}

	@override
	Widget build(BuildContext context) {
		if (context.read<Settings>().useWakeLock) {
			Wakelock.enable();
		}
		var model = context.watch<LocalModel>();

		Set<Equipage> newEquipages = model.model.equipages.values.where(widget.predicate).toSet();
		Set<Equipage> oldEquipages = equipages.toSet();
		equipages.addAll(newEquipages.difference(oldEquipages));

		return Scaffold(
			// backgroundColor: Colors.transparent,
			appBar: AppBar(
				actions: [
					const ConnectionIndicator(),
					SubmitButton(
						onPressed: () {
							int l = min(timerList.length, equipages.length);
							var submission = widget.submit(equipages.sublist(0,l), timerList.times.sublist(0,l));
							setState(() {
								equipages = [];
								timerList.times.clear();
							});
							return submission;
						},
						disabled: timerList.isEmpty,
					)
				],
				title: widget.title,
			),
			body: ListView(
				children: [
					FittedBox(
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 8),
							child: TextClock(),
						)
					),
					Expanded(
						child: TimingList(
							timers: timerList.times,
							onRemoveTimer: (i) => setState(() => timerList.times.removeAt(i)),
							onReorder: (i,j) => setState(() => reorder(i,j,equipages)),
							onReorderRow: (i,dt) => setState(() {
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
													swap(equipages.indexOf(eq), timerList.length, equipages);
													timerList.addNow();
												});
											}
										},
									),
								)
							]
						),
					)
				]
			),
			bottomNavigationBar: EquipageSelectorDrawer(
				onTab: (eq) {
					if (!equipages.contains(eq)) {
						setState(() {
							equipages.add(eq);
						});
					}
			}),
			// floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
			floatingActionButton: FloatingActionButton.large(
				child: const Icon(Icons.timer),
				onPressed: () {
					setState(() {
						timerList.addNow();
					});
				},
			),
		);
	}

}
