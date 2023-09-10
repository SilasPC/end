
import 'package:common/consts.dart';
import 'package:esys_client/util/timer.dart';
import 'package:flutter/material.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:locally/locally.dart';
import 'package:provider/provider.dart';

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

	@override
	Widget build(BuildContext context) {
		Provider.of<LocalModel>(context);

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
				default:
			}
			if (msg != null) {
				int loop = widget.equipage.currentLoop! + 1;
				Locally(
					context: context,
					pageRoute: MaterialPageRoute(builder: (_) => widget),
					payload: "wutisdis",
					appIcon: "mipmap/ic_launcher",
				).show(title: "Status loop $loop", message: msg);
			}
		}

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
			loopCard(l + 1, lps[l], l == lps.length)
		];
	}

	Widget loopCard(int i, LoopData ld, bool finish) =>
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
							children: [
								Text("GATE $i"),
								Text("${ld.loop.distance} km"),
							],
						)
					),
					AspectRatio(
						aspectRatio: 3,
						child: Row(
							children: [
								txtCol([maybe(ld.recoveryTime, unixDifToMS) ?? "-","Recovery"]),
								txtCol(["${ld.data?.hr1 ?? "-"}/${ld.data?.hr2 ?? "-"}","Heartrate"]),
								txtCol([maybe(ld.speed(finish: finish)?.toStringAsFixed(1), (s) => "$s km/h") ?? "-", "Speed"]),
							].map(wrapTxtCol).toList(),
						),
					),
					AspectRatio(
						aspectRatio: 3,
						child: Row(
							children: [
								txtCol([maybe(ld.expDeparture, unixHMS) ?? "-","Departure"]),
								txtCol([maybe(ld.arrival, unixHMS) ?? "-","Arrival"]),
								txtCol([maybe(ld.vet, unixHMS) ?? "-","Vet"]),
							].map(wrapTxtCol).toList(),
						),
					)
					// UI: show vet data remarks
				],
			)
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

	Widget txtCol(List<String> strs) =>
		Column(
			children: strs.map((s) => Text(s)).toList(),
		);

}
