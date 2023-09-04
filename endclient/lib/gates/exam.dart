
import 'package:common/util.dart';
import 'package:esys_client/gates/exam_data.dart';
import 'package:esys_client/gates/gate_controller.dart';
import 'package:esys_client/gates/generic_gate.dart';
import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/util/timer.dart';
import 'package:flutter/material.dart';
import 'package:common/models/glob.dart';

import '../equipage/equipage_tile.dart';

class ExamPage extends StatefulWidget {
	const ExamPage({super.key});

	@override
	State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {

	final GateController _ctrl = GateController();

	@override
	Widget build(BuildContext context) =>
      GenericGate(
         title: TextClock.withPrefix("Exam gate | "),
         comparator: comparator,
         predicate: (eq) => eq.status == EquipageStatus.VET,
         onSubmit: null,
			controller: _ctrl,
         builder: (eq, ok) { // TODO: use ok
				int? vet = eq.currentLoopData?.vet;

				return EquipageTile(
					eq,
					trailing: [
						if (vet != null)
						CountingTimer(target: fromUNIX(vet), countUp: true),
						IconButton(
							icon: const Icon(Icons.send, color: Colors.deepOrange),
							onPressed: () async {
								await Navigator.push(
									context,
									MaterialPageRoute(builder: (context) => ExamDataPage(equipage: eq))
								);
								_ctrl.refresh();
							}
						)
					]
				);
			}
      );

		static int comparator(Equipage a, Equipage b) {
			bool af = a.isFinalLoop, bf = b.isFinalLoop;
			if (af != bf) {
				return af ? -1 : 1;
			}
			return a.compareClassAndEid(b);
		}

}
