

import 'dart:math';

import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/submit_button.dart';
import 'package:esys_client/util/util.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:common/models/glob.dart';
import 'package:wakelock/wakelock.dart';
import '../../services/local_model.dart';
import '../../util/timing_list.dart';
import '../../gates/gate_controller.dart';

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

class _TimingListGateViewState extends State<TimingListGateView> implements GateState {

	List<Equipage> equipages = [];
	TimerList timerList = TimerList();

	@override
	void dispose() {
		super.dispose();
		Wakelock.disable().catchError((_) {});
	}

	@override
	void initState() {
		super.initState();
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
			Wakelock.enable().catchError((_) {});
		}
		var model = context.watch<LocalModel>();

		Set<Equipage> newEquipages = model.model.equipages.values.where(widget.predicate).toSet();
		Set<Equipage> oldEquipages = equipages.toSet();
		equipages.addAll(newEquipages.difference(oldEquipages));

		return
			Row(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					SizedBox(
						width: 400,
						child: EquipagesCard(
							builder: (context, self, eq, color) {
								var inList = equipages.contains(eq);
								return EquipageTile(
									eq,
									trailing: !inList ? const [
										Icon(Icons.chevron_right)
									] : const [
										Icon(null)
									],
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
					SizedBox(
						width: 400,
						child: Scaffold(
							backgroundColor: Colors.transparent,
							body: Card(
								child: ListView(
									children: [
										...cardHeaderWithTrailing(
											"Timings", [
												/* IconButton(
													icon: Icon(Icons.sort),
													onPressed: refresh,
												), */
												SubmitButton(
													onPressed: () {
														int l = min(timerList.length, equipages.length);
														var data = [
															for (int i = 0; i < l; i++)
															(equipages[i], timerList.times[i])
														];
														var submission = widget.submit(data);
														setState(() {
															equipages = [];
															timerList.times.clear();
														});
														return submission;
													},
													disabled: timerList.isEmpty,
												),
											]
										),
										TimingList(
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
									],
								)
							),
							floatingActionButton: FloatingActionButton.large(
								child: const Icon(Icons.timer),
								onPressed: () {
									setState(() {
										timerList.addNow();
									});
								},
							),
						),
					),
				],
			);
	}

}
