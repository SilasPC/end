
import 'package:common/util.dart';
import 'package:esys_client/gates/timing_list_gate.dart';
import 'package:esys_client/services/identity.dart';
import 'package:flutter/material.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:provider/provider.dart';

import '../services/local_model.dart';

class ArrivalPage extends StatelessWidget {
	const ArrivalPage({super.key});

	@override
	Widget build(BuildContext context) =>
		TimingListGate(
			title: const Text("Arrival gate"),
			predicate: (e) => e.status == EquipageStatus.RIDING,
			submit: (List<Equipage> equipages, List<DateTime> times) async {
				LocalModel model = context.read();
				final author = context.read<IdentityService>().author;
				List<EnduranceEvent> evs = [];
				for (int i = 0; i < times.length; i++) {
					evs.add(ArrivalEvent(author, toUNIX(times[i]), equipages[i].eid, equipages[i].currentLoop));
				}
				await model.addSync(evs);
			}
		);

}
