

import 'dart:math';

import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:common/models/glob.dart';

import '../LocalModel.dart';
import '../util/submit_button.dart';
import '../util/timing_list.dart';

class TimingListGate extends StatefulWidget {

	final Widget title;
	final Future<void> Function(List<Equipage> equipages, List<DateTime> times) submit;
	final Predicate<Equipage> predicate;
	const TimingListGate({required this.title, required this.predicate, required this.submit, super.key});

	@override
	State<TimingListGate> createState() => _TimingListGateState();
}

class _TimingListGateState extends State<TimingListGate> {

	List<Equipage> equipages = [];
	TimerList timerList = TimerList();
	bool bottomBarShown = false;

	@override
	Widget build(BuildContext ctx) =>
		Consumer<LocalModel>(
			builder: (context, model, child) {
				
				Set<Equipage> newEquipages = model.model.equipages.values.where(widget.predicate).toSet();
				Set<Equipage> oldEquipages = equipages.toSet();
				equipages.addAll(newEquipages.difference(oldEquipages));

				oldEquipages.difference(newEquipages); // todo: invalidate these

				var winHeight = MediaQuery.of(context).size.height;
				var maxBottomBarHeight = winHeight * 0.7;
				
				return Scaffold(
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
					body: TimingList(
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
					bottomNavigationBar: BottomAppBar(
						// shape: const CircularNotchedRectangle(),
						child: ConstrainedBox(
							constraints: BoxConstraints(maxHeight: maxBottomBarHeight),
							child: ListView(
								shrinkWrap: true,
								children: [
									ElevatedButton(
										child: const Text("More"),
										onPressed: () => setState(() {
											bottomBarShown ^= true;
										}),
									),
									if (bottomBarShown)
									for (var eq in model.model.equipages.values)
									EquipageTile(eq, trailing: [
										IconButton(
											icon: const Icon(Icons.add),
											onPressed: () {
												if (!equipages.contains(eq))
													setState(() {
													  equipages.add(eq);
													});
											},
										)
									],)
								],
							),
						)
					),
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
		);

}
