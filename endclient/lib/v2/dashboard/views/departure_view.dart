
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/Equipage.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/time_lock.dart';
import 'package:esys_client/util/timer.dart';
import 'package:esys_client/v2/dashboard/views/generic_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DepartureView extends StatefulWidget {
	
	const DepartureView({super.key});

	@override
	State<DepartureView> createState() => _DepartureViewState();
}

class _DepartureViewState extends State<DepartureView> {
	
	Map<int, DateTime> timers = {};

	@override
	Widget build(BuildContext context) =>
		GenericGateView(
			submitDisabled: timers.isEmpty,
			predicate: (eq) => eq.status.isRESTING,
			comparator: comparator,
			submit: () async {
				LocalModel model = context.read();
				final author = model.id;
				List<EnduranceEvent> evs = [];
				for (var MapEntry(:key, :value) in timers.entries) {
					var eq = model.model.equipages[key]!;
					evs.add(DepartureEvent(author, toUNIX(value), eq.eid, eq.currentLoop));
				}
				await context.read<LocalModel>().addSync(evs);
			},
			builder: (eq) =>
				EquipageTile(
					eq,
					trailing: [
						if (eq.currentLoopData?.expDeparture case int expDep)
						if (!timers.containsKey(eq.eid)/*  && ok */)
						CountingTimer(
							target: fromUNIX(expDep)
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
