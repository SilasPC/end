
import 'package:common/util.dart';
import 'package:esys_client/gates/exam_data.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/util/timer.dart';
import 'package:flutter/material.dart';
import 'package:common/model.dart';
import 'package:provider/provider.dart';

import '../LocalModel.dart';
import '../equipage/equipage_tile.dart';

class ExamPage extends StatefulWidget {
	const ExamPage({super.key});

	@override
	State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {

	List<Widget> buildList(BuildContext context, List<Equipage> eqs)
		=> ([...eqs /*just in case*/]
			..sort(Equipage.byClassAndEid))
			.where((eq) => eq.status == EquipageStatus.VET)
			.map<Widget>((eq) {
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
									MaterialPageRoute(builder: (context) => ExamDataPage(equipage: eq))
								),
						)
					]
				);
			})
			.toList();

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: TextClock.withPrefix("Exam gate | "),
				actions: const [ConnectionIndicator()],
			),
			body: Consumer<LocalModel>(
				builder: (context, model, child) => 
					ListView(
						children: buildList(
							context,
							model.model.equipages.values.toList()
						),
					)
			)
		);

}
