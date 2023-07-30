
import 'package:common/util.dart';
import 'package:esys_client/gates/timing_list_gate.dart';
import 'package:flutter/material.dart';
import 'package:common/AbstractEventModel.dart';
import 'package:common/Event.dart';
import 'package:common/models/glob.dart';

import '../LocalModel.dart';
import '../util/text_clock.dart';

class VetPage extends StatelessWidget {
	const VetPage({super.key});
	
	@override
	Widget build(BuildContext context) =>
		TimingListGate(
			title: TextClock.withPrefix("Vet gate | "),
			getEquipages: (m) =>
				m.equipages.values
					.where((e) => e.status == EquipageStatus.COOLING)
					.toSet(),
			submit: (List<Equipage> equipages, List<DateTime> times) async {
				List<Event> evs = [];
				for (int i = 0; i < times.length; i++) {
					evs.add(VetEvent(LocalModel.instance.author, toUNIX(times[i]), equipages[i].eid, equipages[i].currentLoop!));
				}
				await LocalModel.instance.addAndSync(evs);
			}
		);

}
