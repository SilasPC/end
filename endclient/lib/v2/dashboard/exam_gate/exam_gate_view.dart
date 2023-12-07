
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:esys_client/util/numpad.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/exam_gate/loop_card.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// UI: phone layout
class ExamGateView extends StatefulWidget {
	const ExamGateView({super.key});

	@override
	State<ExamGateView> createState() => _ExamGateViewState();
}

class _ExamGateViewState extends State<ExamGateView> {

	Equipage? equipage;
	VetData data = VetData.empty();

	Future<void> submit(bool passed, {bool retire = false}) async {
		if (equipage case Equipage equipage) {
			var author = context.read<Settings>().author;
			var model = context.read<LocalModel>();
			data.passed = passed;
			int now = nowUNIX();
			model.addSync([
				ExamEvent(author, now, equipage.eid, data, equipage.currentLoop),
				if (retire)
					RetireEvent(author, now + 1, equipage.eid)
			]);
			setState(() {
			  this.equipage = null;
			  data = VetData.empty();
			});
		}
	}
	
	@override
	Widget build(BuildContext context) {

		// LocalModel model = context.watch();

		// UI: flex width => layout change when needed
		return Row(
			children: [
				SizedBox(
					width: 300,
					child: Column(
						children: [
							Expanded(
								child: EquipagesCard(
									builder: EquipagesCard.withChevrons,
									onTap: (eq) => setState(() {equipage = eq;}),
									filter: (e) => e.status == EquipageStatus.VET,
									emptyLabel: "None ready for examination",
								),
							),
							Card(
								child: AspectRatio(
									aspectRatio: 1.37,
									// UI: use this for searching
									child: Numpad(onAccept: (_) {}),
								)
							)
						],
					),
				),
				SizedBox(
					width: 400,
					child: Card(
						child: Padding(
							padding: const EdgeInsets.all(10),
							child: Column(
								verticalDirection: VerticalDirection.up,
								children: [
									Row(
										children: [
											Flexible(
												fit: FlexFit.tight,
												flex: 2,
												child: ElevatedButton(
													style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 12)),
													child: const Text("FAIL", style: TextStyle(fontSize: 20)),
													onPressed: () => submit(false),
												),
											),
											Flexible(
												fit: FlexFit.tight,
												flex: 3,
												child: Padding(
													padding: const EdgeInsets.symmetric(horizontal: 12),
													child: ElevatedButton(
														style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
														child: const Text("PASS", style: TextStyle(fontSize: 20)),
														onPressed: () => submit(true),
													),
												)
											),
											Flexible(
												fit: FlexFit.tight,
												flex: 2,
												child: ElevatedButton(
													style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 12)),
													child: const Text("RETIRE", style: TextStyle(fontSize: 20)),
													onPressed: () => submit(true, retire: true),
												),
											)
										],
									),
									Expanded(
										child: GridView.count(
											crossAxisCount: 3,
											mainAxisSpacing: 10,
											crossAxisSpacing: 10,
											children: [
												field(VetField.HR1, data.hr1, (n) => setState(() => data.hr1 = n)),
												field(VetField.HR2, data.hr2, (n) => setState(() => data.hr2 = n)),
												field(VetField.RESP, data.resp, (n) => setState(() => data.resp = n)),

												field(VetField.MUC_MEM, data.mucMem, (n) => setState(() => data.mucMem = n)),
												field(VetField.CAP, data.cap, (n) => setState(() => data.cap = n)),
												field(VetField.JUG, data.jug, (n) => setState(() => data.jug = n)),

												field(VetField.HYDR, data.hydr, (n) => setState(() => data.hydr = n)),
												field(VetField.GUT, data.gut, (n) => setState(() => data.gut = n)),
												field(VetField.SORE, data.sore, (n) => setState(() => data.sore = n)),

												field(VetField.WNDS, data.wounds, (n) => setState(() => data.wounds = n)),
												field(VetField.GAIT, data.gait, (n) => setState(() => data.gait = n)),
												field(VetField.ATT, data.attitude, (n) => setState(() => data.attitude = n)),
											]
										),
									),
								],
							),
						)
					)
				),
				Expanded(
					child: Card( // UI: flex/wrap whatever layout
						child: Column(
							children: [
								...cardHeader("Equipage info"),
								if (equipage case Equipage equipage) ...[
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
								]
								else
								emptyListText("Select an equipage")
							],
						),
					),
				)
			],
		);
	}

	Widget field(VetField field, int? val, void Function(int? n) f) =>
		ElevatedButton(
			style: ElevatedButton.styleFrom(
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(20),
				),
				padding: const EdgeInsets.all(8),
			),
			onLongPress: () => f(null),
			onPressed: () {
				switch (field.type) {
					case VetFieldType.NUMBER:
						f(null);
						showIntPicker(
							context,
							(n) {
								f(n);
								Navigator.pop(context);
							}
						);
						break;
					default:
						if (val case int value) {
							val = (value + 1) % 4;
							if (val == 0) val = null;
						} else {
							val = 1;
						}
						f(val);
						break;
				}
			},
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(
						val != null ? field.withValue(val).toString() : "-",
						style: const TextStyle(
							fontSize: 28,
							fontWeight: FontWeight.bold
						),
					),
					Text(
						field.name,
						textAlign: TextAlign.center,
					),
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
