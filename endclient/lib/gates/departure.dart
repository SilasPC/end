
import 'package:common/AbstractEventModel.dart';
import 'package:common/Event.dart';
import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/gates/generic_gate.dart';
import 'package:esys_client/util/timer.dart';
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

	Future<void> submit(BuildContext ctx) async {
		LocalModel m = Provider.of(ctx, listen: false);
		List<Event> evs = timers.entries
			.map((kv) => DepartureEvent(LocalModel.instance.author, toUNIX(kv.value), kv.key, m.model.equipages[kv.key]!.currentLoop!))
			.toList();
		await m.addAndSync(evs);
		timers.clear();
	}

	@override
	Widget build(BuildContext ctx) =>
      GenericGate(
         title: TextClock.withPrefix("Departure gate | "),
         comparator: Equipage.byEid, // todo: by departure
         predicate: (e) => e.status == EquipageStatus.RESTING,
         onSubmit: () => submit(ctx),
         submitDisabled: timers.isEmpty,
         builder: (eq, ok) => // todo: use ok
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
      );

}
