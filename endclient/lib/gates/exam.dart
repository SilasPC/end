
import 'package:common/util.dart';
import 'package:esys_client/gates/exam_data.dart';
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

	@override
	Widget build(BuildContext context) =>
      GenericGate(
         title: TextClock.withPrefix("Exam gate | "),
         comparator: Equipage.byClassAndEid,
         predicate: (eq) => eq.status == EquipageStatus.VET,
         onSubmit: () async {}, // todo: make this unnescessary
         submitDisabled: true,
         builder: (eq, ok) { // todo: use ok
				int? vet = eq.currentLoopData?.vet;

				return EquipageTile(
					eq,
					trailing: [
						if (vet != null)
						CountingTimer(target: fromUNIX(vet), countUp: true),
						IconButton(
							icon: const Icon(Icons.send, color: Colors.deepOrange),
							onPressed: () =>
								Navigator.push(
									context,
									MaterialPageRoute(builder: (context) => ExamDataPage(equipage: eq),
                              maintainState: false) // todo: should work differently
								),
						)
					]
				);
			}
      );

}
