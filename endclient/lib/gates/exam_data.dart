
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';

import '../settings_provider.dart';
import '../util/input_modals.dart';
import '../LocalModel.dart';

class ExamDataPage extends StatefulWidget {

	final Equipage equipage;

	const ExamDataPage({super.key, required this.equipage});

	@override
	State<ExamDataPage> createState() => _ExamDataPageState();
}

class _ExamDataPageState extends State<ExamDataPage> {

	VetData data = VetData.empty();

	Future<void> submit(BuildContext context, bool passed, {bool retire = false}) async {
		var author = context.read<Settings>().author;
		var model = context.read<LocalModel>();
		data.passed = passed;
		int now = nowUNIX();
		model.addSync([
			ExamEvent(author, now, widget.equipage.eid, data, widget.equipage.currentLoop),
			if (retire)
				RetireEvent(author, now + 1, widget.equipage.eid)
		]);
		Navigator.pop(context);
	}

	Widget textCol(String title, String subtitle) =>
		Column(
			children: [
				Text(title, style: const TextStyle(fontSize: 20)),
				Text(subtitle, style: const TextStyle()),
			],
		);

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: Text("${widget.equipage.eid} ${widget.equipage.rider}"),
			),
			body:	Column(
				children: [
					Card(
						margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
						color: const Color.fromARGB(255, 146, 119, 68),
						child: Container(
							height: 50,
							padding: const EdgeInsets.only(right: 10),
							child: ListView(
								scrollDirection: Axis.horizontal,
								children: [
									paddedChip("Loop ${1 + (widget.equipage.currentLoop ?? -1)}/${widget.equipage.category.loops.length}"),
									if (widget.equipage.currentLoopData?.recoveryTime != null)
										paddedChip("Recovery ${unixDifToMS(widget.equipage.currentLoopData!.recoveryTime!)}"),
									for (VetFieldValue remark in widget.equipage.previousLoopData?.data?.remarks(true) ?? const [])
										paddedChip("${remark.field.name} ${remark.toString()}", Colors.amber)
								],
							),
						),
					),
					Expanded(
						child: GridView.count(
							padding: const EdgeInsets.all(10),
							mainAxisSpacing: 10,
							crossAxisSpacing: 10,
							crossAxisCount: 3,
							children: [
								numField(context, data.hr1,"Pulse 1", (n) => setState(() => data.hr1 = n)),
								numField(context, data.hr2,"Pulse 2", (n) => setState(() => data.hr2 = n)),
								letField(data.resp,"Respiration", (n) => setState(() => data.resp = n)),
								
								digField(data.mucMem,"Mucous Membranes", (n) => setState(() => data.mucMem = n)),
								digField(data.cap,"Capilary refill", (n) => setState(() => data.cap = n)),
								digField(data.jug,"Jugular refill", (n) => setState(() => data.jug = n)),
								
								digField(data.hydr,"Dehydration", (n) => setState(() => data.hydr = n)),
								letField(data.gut,"Gut sounds", (n) => setState(() => data.gut = n)),
								letField(data.sore,"Soreness", (n) => setState(() => data.sore = n)),
								
								letField(data.wounds,"Wounds", (n) => setState(() => data.wounds = n)),
								letField(data.gait,"Gait", (n) => setState(() => data.gait = n)),
								letField(data.attitude,"Attitude", (n) => setState(() => data.attitude = n)),
							]
						),
					),
					AspectRatio(
						aspectRatio: 6,
						child: Row(
							children: [
								AspectRatio(
									aspectRatio: 1.75,
									child: Container(
									margin: const EdgeInsets.all(10),
									child: ElevatedButton(
										style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
										onPressed: () => submit(context, false),
										child: const Text("FAIL", style: TextStyle(fontSize: 20)),
									)
									),
								),
								AspectRatio(
									aspectRatio: 2.5,
									child: Container(
									margin: const EdgeInsets.all(10),
									child: ElevatedButton(
										style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
										onPressed: () => submit(context, true),
										child: const Text("PASS", style: TextStyle(fontSize: 20)),
									)
									),
								),
								AspectRatio(
									aspectRatio: 1.75,
									child: Container(
									margin: const EdgeInsets.all(10),
									child: ElevatedButton(
										style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
										onPressed: () => submit(context, true, retire: true),
										child: const Text("RETIRE", style: TextStyle(fontSize: 20)),
									)
									),
								),
							]
						)
					)
				],
			)
		);
	
	Widget paddedChip(String label, [Color? color]) =>
		Padding(
			padding: const EdgeInsets.only(left: 10),
			child: Chip(
				backgroundColor: color,
				label: Text(label)
			),
		);

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
					Text(val == null ? "-" : val.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
					Text(display),
				],
			),
		);

	Widget digField(int? val, String display, void Function(int? n) f) =>
		ElevatedButton(
			onPressed: (){
				if (val == null) {
					val = 1;
				} else {
					val = (val! + 1) % 4;
					if (val == 0) val = null;
				}
				f(val);
			},
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(val == null ? "-" : val.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
					Text(display),
				],
			),
		);

	Widget letField(int? val, String display, void Function(int? n) f) =>
		ElevatedButton(
			onPressed: (){
				if (val == null) {
					val = 1;
				} else {
					val = (val! + 1) % 4;
					if (val == 0) val = null;
				}
				f(val);
			},
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(val == null ? "-" : String.fromCharCode(64 + val), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
					Text(display),
				],
			),
		);

}
