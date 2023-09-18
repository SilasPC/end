
import 'package:common/EnduranceEvent.dart';
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
import '../settings_provider.dart';

class DeparturePage extends StatefulWidget {
	const DeparturePage({super.key});

	@override
	State<DeparturePage> createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {

	Map<int, DateTime> timers = {};

	Future<void> submit(BuildContext ctx) async {
		LocalModel m = ctx.read<LocalModel>();
		var author = ctx.read<Settings>().author;
		List<EnduranceEvent> evs = timers.entries
			.map((kv) => DepartureEvent(author, toUNIX(kv.value), kv.key, m.model.equipages[kv.key]!.currentLoop!))
			.toList();
		await m.addSync(evs);
		timers.clear();
	}

	@override
	Widget build(BuildContext ctx) =>
      GenericGate(
         title: TextClock.withPrefix("Departure gate | "),
         comparator: comparator,
         predicate: (e) => e.status == EquipageStatus.RESTING,
         onSubmit: () => submit(ctx),
         submitDisabled: timers.isEmpty,
         builder: (eq, ok) =>
            EquipageTile(
               eq,
               trailing: [
                  if (!timers.containsKey(eq.eid) && ok)
                  CountingTimer(
                     target: fromUNIX(eq.currentLoopData!.expDeparture!)
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

	static int comparator(Equipage a, Equipage b) {
		int ad = a.currentLoopData?.expDeparture ?? UNIX_FUTURE;
		int bd = b.currentLoopData?.expDeparture ?? UNIX_FUTURE;
		int dif = ad - bd;
		return dif == 0 ? a.eid - b.eid : dif;
	}

}
