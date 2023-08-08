
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
			getEquipages: (m) =>
				m.equipages.values
					.where((e) => e.status == EquipageStatus.RIDING)
					.toSet(),
			submit: (List<Equipage> equipages, List<DateTime> times) async {
				List<EnduranceEvent> evs = [];
				for (int i = 0; i < times.length; i++) {
					evs.add(ArrivalEvent(LocalModel.instance.author, toUNIX(times[i]), equipages[i].eid, equipages[i].currentLoop!));
				}
				await LocalModel.instance.addAndSync(evs);
			}
		);

}
