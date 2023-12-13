
import 'package:common/EnduranceEvent.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/v2/dashboard/views/timing_list_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VetView extends StatelessWidget {
	
	const VetView({super.key});

	@override
	Widget build(BuildContext context) =>
		TimingListGateView(
			predicate: (eq) => eq.status.isCOOLING,
			submit: (data) async {
				var author = context.read<Settings>().author;
				List<EnduranceEvent> evs = [];
				for (var (eq, dt) in data) {
					evs.add(VetEvent(author, toUNIX(dt), eq.eid, eq.currentLoop));
				}
				await context.read<LocalModel>().addSync(evs);
			},
		);
}
