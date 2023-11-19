
import 'package:common/util.dart';
import 'package:esys_client/gates/timing_list_gate.dart';
import 'package:flutter/material.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:provider/provider.dart';

import '../local_model/LocalModel.dart';
import '../settings_provider.dart';

class ArrivalPage extends StatelessWidget {
	const ArrivalPage({super.key});
	
	@override
	Widget build(BuildContext context) =>
		TimingListGate(
			title: const Text("Arrival gate"),
			predicate: (e) => e.status == EquipageStatus.RIDING,
			submit: (List<Equipage> equipages, List<DateTime> times) async {
				var author = context.read<Settings>().author;
				List<EnduranceEvent> evs = [];
				for (int i = 0; i < times.length; i++) {
					evs.add(ArrivalEvent(author, toUNIX(times[i]), equipages[i].eid, equipages[i].currentLoop!));
				}
				await context.read<LocalModel>().addSync(evs);
			}
		);

}
