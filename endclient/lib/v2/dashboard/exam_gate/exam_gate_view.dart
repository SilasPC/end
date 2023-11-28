
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:common/EnduranceEvent.dart';
import 'package:common/models/VetData.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/secretary/util.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/chip_strip.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:esys_client/util/numpad.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class ExamGateView extends StatefulWidget {
	const ExamGateView({super.key});

	@override
	State<ExamGateView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<ExamGateView> {

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
													child: Text("FAIL", style: TextStyle(fontSize: 20)),
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
														child: Text("PASS", style: TextStyle(fontSize: 20)),
														onPressed: () => submit(true),
													),
												)
											),
											Flexible(
												fit: FlexFit.tight,
												flex: 2,
												child: ElevatedButton(
													style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 12)),
													child: Text("RETIRE", style: TextStyle(fontSize: 20)),
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
												numField(context, data.hr1,"Pulse 1", (n) => setState(() => data.hr1 = n)),
												numField(context, data.hr2,"Pulse 2", (n) => setState(() => data.hr2 = n)),
												letField(data.resp,"Respiration", (n) => setState(() => data.resp = n)),

												digField(data.mucMem,"Mucous membranes", (n) => setState(() => data.mucMem = n)),
												digField(data.cap,"Capilary refill", (n) => setState(() => data.cap = n)),
												digField(data.jug,"Jugular refill", (n) => setState(() => data.jug = n)),

												digField(data.hydr,"Hydration", (n) => setState(() => data.hydr = n)),
												letField(data.gut,"Gut sounds", (n) => setState(() => data.gut = n)),
												letField(data.sore,"Soreness", (n) => setState(() => data.sore = n)),

												letField(data.wounds,"Wounds", (n) => setState(() => data.wounds = n)),
												letField(data.gait,"Gait", (n) => setState(() => data.gait = n)),
												letField(data.attitude,"Attitude", (n) => setState(() => data.attitude = n)),
											]
										),
									),
								],
							),
						)
					)
				),
				SizedBox(
					width: 300,
					child: Card(
						child: Column(
							children: [
								// UI: loops, prev-data, general info
								if (equipage case Equipage equipage) ...[
									EquipageTile(equipage),
									ListTile(
										title: Text("Loop"),
										trailing: Text("${equipage.currentLoopOneIndexed ?? "-"}/${equipage.category.loops.length}"),
										/* Slider(
											divisions: equipage.category.loops.length ,
											min: -1,
											max: equipage.category.loops.length.toDouble(),
											value: (equipage.currentLoop ?? -1).toDouble(),
											onChanged: null,
										), */
									),
									Expanded(
										child: ListView(
											children: loopCards(equipage),
										),
									)
								]
								else
								Container(
									alignment: Alignment.topCenter,
									padding: const EdgeInsets.only(top: 16),
									child: Text(
										"Select an equipage",
										style: TextStyle(
											fontSize: 16,
											fontStyle: FontStyle.italic,
										)
									),
								)
							],
						),
					),
				),
			],
		);
	}

	Widget numField(BuildContext context, int? val, String display, void Function(int? n) f) =>
		ElevatedButton(
			onLongPress: () => f(null),
			onPressed: () {
				showIntPicker(
					context,
					(n) {
						f(n);
						Navigator.pop(context);
					}
				);
			},
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(val == null ? "-" : val.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),),
					Text(display, textAlign: TextAlign.center,),
				],
			),
		);

	Widget digField(int? val, String display, void Function(int? n) f) =>
		ElevatedButton(
			onPressed: (){
				if (val case int value) {
					val = (value + 1) % 4;
					if (val == 0) val = null;
				} else {
					val = 1;
				}
				f(val);
			},
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(val == null ? "-" : val.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
					Text(display, textAlign: TextAlign.center,),
				],
			),
		);

	Widget letField(int? val, String display, void Function(int? n) f) =>
		ElevatedButton(
			onPressed: () {
				if (val case int value) {
					val = (value + 1) % 4;
					if (val == 0) val = null;
				} else {
					val = 1;
				}
				f(val);
			},
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(val == null ? "-" : String.fromCharCode(64 + val), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
					Text(display, textAlign: TextAlign.center,),
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
				Card(
					child: Column(
						children: [
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 10),
								decoration: BoxDecoration(
									color: primaryColor,
									borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
									border: Border.all(
										color: Colors.black54,
										width: 0.3,
									),
								),
								height: 30,
								child: const Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										Text("PRE-EXAM"),
									],
								)
							),
							LoopCard.remarksList(vd.remarks())
						],
					),
				)
		];
	}

}

class LoopCard extends StatelessWidget {

	const LoopCard({super.key, required this.loopNr, required this.loopData, required this.isFinish});

	final int loopNr;
	final LoopData loopData;
	final bool isFinish;

	@override
	Widget build(BuildContext context) {
		var remarks = loopData.data?.remarks() ?? const [];
		return Card(
			child: Column(
				children: [
					header(),
					grid(),
					if (remarks.isNotEmpty)
					remarksList(remarks),
				],
			)
		);
	}

	static Widget remarksList(List<VetFieldValue> remarks, [Color? color = Colors.amber]) =>
		// UI: expand horizontally
		Container(
			decoration: BoxDecoration(
				border: Border.all(
					color: Colors.black54,
					width: 0.3,
				),
			),
			padding: const EdgeInsets.all(4),
			child: Wrap(
				runSpacing: 4,
				spacing: 4,
				children: [
					for (var remark in remarks)
					Chip(
						backgroundColor: color,
						label: Text("${remark.field.name} ${remark.toString()}")
					),
					if (remarks.isEmpty)
					const Chip(
						backgroundColor: Colors.green,
						label: Text("No remarks!")
					)
				],
			)
		);

	Widget header() =>
		Container(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			decoration: BoxDecoration(
				color: primaryColor,
				borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
				border: Border.all(
					color: Colors.black54,
					width: 0.3,
				),
			),
			height: 30,
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text("LOOP $loopNr"),
					Text("${loopData.loop.distance} km"),
				],
			)
		);

	Widget grid() =>
		AspectRatio(
			aspectRatio: 3/2,
			child: GridView.count(
				crossAxisCount: 3,
				children: [
					txtCol([maybe(loopData.recoveryTime, unixDifToMS) ?? "-","Recovery"]),
					txtCol(["${loopData.data?.hr1 ?? "-"}/${loopData.data?.hr2 ?? "-"}","Heartrate"]),
					txtCol([maybe(loopData.speed(finish: isFinish)?.toStringAsFixed(1), (s) => "$s km/h") ?? "-", "Speed"]),
					txtCol([maybe(loopData.expDeparture, unixHMS) ?? "-","Departure"]),
					txtCol([maybe(loopData.arrival, unixHMS) ?? "-","Arrival"]),
					txtCol([maybe(loopData.vet, unixHMS) ?? "-","Vet"]),
				].map(wrapTxtCol).toList(),
			),
		);

}

Widget txtCol(List<String> strs) =>
	Column(
		children: strs.map((s) => Text(s)).toList(),
	);

Widget wrapTxtCol(Widget w) =>
	AspectRatio(
		aspectRatio: 1,
		child: Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				border: Border.all(
					color: Colors.black54,
					width: 0.3,
				),
			),
			child: FittedBox(
				child: w,
			),
		)
	);
