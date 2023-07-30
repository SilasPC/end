
import 'package:common/AbstractEventModel.dart';
import 'package:common/Event.dart';
import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/timer.dart';
import 'package:esys_client/util/submit_button.dart';
import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/util/time_lock.dart';
import 'package:flutter/material.dart';
import 'package:common/models/glob.dart';
import 'package:provider/provider.dart';

import '../LocalModel.dart';

class DeparturePage extends StatefulWidget {
	const DeparturePage({super.key});

	@override
	State<DeparturePage> createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {

	Map<int, DateTime> timers = {};
	List<Equipage> equipages = [];

	Future<void> submit(BuildContext ctx) async {
		LocalModel m = Provider.of(ctx, listen: false);
		List<Event> evs = timers.entries
			.map((kv) => DepartureEvent(LocalModel.instance.author, toUNIX(kv.value), kv.key, m.model.equipages[kv.key]!.currentLoop!))
			.toList();
		await m.addAndSync(evs);
		timers.clear();
	}

	Widget buildList(BuildContext ctx) =>
		Consumer<LocalModel>(
			builder: (context, model, child) {

				Set<Equipage> newEquipages =
					model.model.equipages.values
						.where((e) => e.status == EquipageStatus.RESTING)
						.toSet();
				
				Set<Equipage> oldEquipages = equipages.toSet();
				equipages.addAll(newEquipages.difference(oldEquipages));

				oldEquipages.difference(newEquipages); // todo: invalidate these

				return ListView(
					children: [
						for (var eq in equipages)
						EquipageTile(
							eq,
							trailing: [
								if (!timers.containsKey(eq.eid))
								CountingTimer(
									target: fromUNIX(eq.loops[eq.currentLoop!].expDeparture!)
								),
								TimeLock(
									time: timers[eq.eid],
									onChanged: (dt) => setState((){
										timers[eq.eid] = dt;
									}),
								)
							],
						)
					],
				);
			}
		);

	@override
	Widget build(BuildContext ctx) =>
		Scaffold(
			appBar: AppBar(
				actions: [
					const ConnectionIndicator(),
					SubmitButton(
						onPressed: () => submit(ctx),
						disabled: timers.isEmpty,
					)
				],
				title: TextClock.withPrefix("Departure gate | "),
			),
			body: buildList(ctx),
		);

}
