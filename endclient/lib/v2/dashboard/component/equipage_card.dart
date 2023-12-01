
import 'package:common/models/Equipage.dart';
import 'package:common/models/glob.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/v2/dashboard/exam_gate/loop_card.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';

class EquipageInfoCard extends StatelessWidget {

	final Equipage equipage;

	const EquipageInfoCard(this.equipage, {super.key});

	@override
	Widget build(BuildContext context) =>
		Card(
			child: Column(
				children: [
					...cardHeader("Equipage info"),
					EquipageTile(equipage),
					ListTile(
						title: const Text("Loop"),
						trailing: Text("${equipage.currentLoopOneIndexed ?? "-"}/${equipage.category.loops.length}"),
					),
					Expanded(
						child: ListView(
							children: loopCards(equipage),
						),
					)
				],
			),
		);

	List<Widget> loopCards(Equipage equipage) {
		var lps = equipage.loops;
		int? cl = equipage.currentLoop;
		if (cl == null) return [];
		return [
			for (int l = cl; l >= 0; l--)
				LoopCard(loopNr: l + 1, loopData: lps[l], isFinish: l == lps.length),
			if (equipage.preExam case VetData vd)
				LoopCard.preExam(vd)
		];
	}

}
