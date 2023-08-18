
import 'package:common/util.dart';
import 'package:esys_client/gates/timing_list_gate.dart';
import 'package:flutter/material.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';

import '../LocalModel.dart';
import '../util/text_clock.dart';

class ArrivalPage extends StatelessWidget {
	const ArrivalPage({super.key});
	
	@override
	Widget build(BuildContext context) =>
		TimingListGate(
			title: TextClock.withPrefix("Arrival gate | "),
			predicate: (e) => e.status == EquipageStatus.RIDING,
			submit: (List<Equipage> equipages, List<DateTime> times) async {
				List<EnduranceEvent> evs = [];
				for (int i = 0; i < times.length; i++) {
					evs.add(ArrivalEvent(LocalModel.instance.author, toUNIX(times[i]), equipages[i].eid, equipages[i].currentLoop!));
				}
				await LocalModel.instance.addSync(evs);
			}
		);

}
