
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:locally/locally.dart';
import 'package:provider/provider.dart';

import 'package:common/consts.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';

import '../settings_provider.dart';
import '../util/chip_strip.dart';
import '../util/timer.dart';
import 'equipage_tile.dart';

import '../LocalModel.dart';

class EquipagePage extends StatefulWidget {

	final Equipage equipage;

	const EquipagePage(this.equipage, {super.key});
	@override
	EquipagePageState createState() => EquipagePageState();
}

class EquipagePageState extends State<EquipagePage> {

	late EquipageStatus _prevStatus;

	@override
	void initState() {
		super.initState();
		_prevStatus = widget.equipage.status;
	}

	void checkStatusUpdate() {
		if (_prevStatus != widget.equipage.status) {
			_prevStatus = widget.equipage.status;
			String? msg;
			switch (_prevStatus) {
				case EquipageStatus.COOLING:
					var time = widget.equipage.currentLoopData?.arrival;
					if (time == null) break;
					msg = "Exam attendance before ${unixHMS(time + COOL_TIME)}";
					break;
				case EquipageStatus.RESTING:
					var time = widget.equipage.currentLoopData?.expDeparture;
					if (time == null) break;
					msg = "Departure time ${unixHMS(time)}";
					break;
				case EquipageStatus.FINISHED:
					var pos = (widget.equipage.category.equipages.toList()
						..sort(Equipage.byRank))
						.indexOf(widget.equipage) + 1;
					msg = "Finished as #$pos";
					break;
				default:
			}
			if (msg != null && context.read<Settings>().sendNotifs) {
				int loop = widget.equipage.currentLoop! + 1;
				Locally(
					context: context,
					pageRoute: MaterialPageRoute(builder: (_) => widget),
					payload: "wutisdis",
					appIcon: "mipmap/ic_launcher",
				).show(title: "Status loop $loop", message: msg);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		context.watch<LocalModel>();
		checkStatusUpdate();
		return Scaffold(
			appBar: AppBar(
				title: const Text("Equipage"),
			),
			bottomNavigationBar: bottomBar(),
			body: Container(
				padding: const EdgeInsets.all(10),
				child: ListView(
					children: [
						Card(
							child: EquipageTile(widget.equipage, color: const Color.fromARGB(255, 228, 190, 53)),
						),
						...loopCards(),
					],
				)
			)
		);
	}

	Widget? bottomBar() {
		if (widget.equipage.status != EquipageStatus.COOLING) {
			return null;
		}
		int target = widget.equipage.currentLoopData!.arrival! + COOL_TIME;
		return BottomAppBar(
			child: CountingTimer(target: fromUNIX(target)),
		);
	}
	
	List<Widget> loopCards() {
		var lps = widget.equipage.loops;
		int? cl = widget.equipage.currentLoop;
		if (cl == null) return [];
		return [
			for (int l = cl; l >= 0; l--)
				LoopCard(i: l + 1, ld: lps[l], finish: l == lps.length),
			if (widget.equipage.preExam != null)
				Card(
					child: Column(
						children: [
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 10),
								decoration: BoxDecoration(
									color: const Color.fromARGB(255, 98, 85, 115),
									border: Border.all(
										color: Colors.black54,
										width: 0.3,
									),
								),
								height: 30,
								child: Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: const [
										Text("PRE-EXAM"),
									],
								)
							),
							LoopCard.remarksList(widget.equipage.preExam!.remarks())
						],
					),
				)
		];
	}

}

class LoopCard extends StatelessWidget {

	const LoopCard({super.key, required this.i, required this.ld, required this.finish});

	final int i;
	final LoopData ld;
	final bool finish;

	@override
	Widget build(BuildContext context) {
		var remarks = ld.data?.remarks() ?? const [];
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
		ChipStrip(
			decoration: BoxDecoration(
				border: Border.all(
					color: Colors.black54,
					width: 0.3,
				),
			),
			chips: [
				for (var remark in remarks)
				Chip(
					backgroundColor: color,
					label: Text("${remark.field.name} ${remark.toString()}")
				)
			],
		);

	Widget header() =>
		Container(
			padding: const EdgeInsets.symmetric(horizontal: 10),
			decoration: BoxDecoration(
				color: const Color.fromARGB(255, 98, 85, 115),
				border: Border.all(
					color: Colors.black54,
					width: 0.3,
				),
			),
			height: 30,
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text("GATE $i"),
					Text("${ld.loop.distance} km"),
				],
			)
		);

	Widget grid() =>
		AspectRatio(
			aspectRatio: 3/2,
			child: GridView.count(
				crossAxisCount: 3,
				children: [
					txtCol([maybe(ld.recoveryTime, unixDifToMS) ?? "-","Recovery"]),
					txtCol(["${ld.data?.hr1 ?? "-"}/${ld.data?.hr2 ?? "-"}","Heartrate"]),
					txtCol([maybe(ld.speed(finish: finish)?.toStringAsFixed(1), (s) => "$s km/h") ?? "-", "Speed"]),
					txtCol([maybe(ld.expDeparture, unixHMS) ?? "-","Departure"]),
					txtCol([maybe(ld.arrival, unixHMS) ?? "-","Arrival"]),
					txtCol([maybe(ld.vet, unixHMS) ?? "-","Vet"]),
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
