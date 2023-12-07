
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/consts.dart';
import 'package:flutter/material.dart';

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
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					header(),
					grid(),
					if (remarks.isNotEmpty)
					remarksList(remarks),
				],
			)
		);
	}

	static Widget preExam(VetData data) =>
		Card(
			elevation: 0,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 10),
						decoration: BoxDecoration(
							color: primaryColor,
							borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
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
					remarksList(data.remarks())
				],
			),
		);

	static Widget remarksList(List<VetFieldValue> remarks, [Color? color = Colors.amber]) =>
		Container(
			decoration: BoxDecoration(
				border: Border.all(
					color: Colors.black54,
					width: 0.3,
				),
			),
			padding: const EdgeInsets.all(4),
			child: Wrap(
				alignment: WrapAlignment.center,
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
				borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
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
