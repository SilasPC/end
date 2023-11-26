
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/gates/arrival.dart';
import 'package:esys_client/gates/departure.dart';
import 'package:esys_client/gates/exam.dart';
import 'package:esys_client/gates/vet.dart';
import 'package:esys_client/util/numpad.dart';
import 'package:flutter/material.dart';

class GateView extends StatefulWidget {

	const GateView({super.key});

	@override
	State<GateView> createState() => _GateViewState();
}

class _GateViewState extends State<GateView> {

	Widget page = DeparturePage();

	@override
	Widget build(BuildContext context) =>
		Row(
			children: [
				Card(
					color: Colors.black26,
					child: Container(
						padding: const EdgeInsets.all(8),
						width: 120,
						child: ListView(
							children: [
								ElevatedButton(
									child: Text("Departure"),
									onPressed: () => setState(() => page = DeparturePage()),
								),
								SizedBox(height: 10,),
								ElevatedButton(
									child: Text("Arrival"),
									onPressed: () => setState(() => page = ArrivalPage()),
								),
								SizedBox(height: 10,),
								ElevatedButton(
									child: Text("Vet"),
									onPressed: () => setState(() => page = VetPage()),
								),
								SizedBox(height: 10,),
								ElevatedButton(
									child: Text("Exam"),
									onPressed: () => setState(() => page = ExamPage()),
								),
							],
						)
					)
				),
				Card(
					color: Colors.black26,
					child: SizedBox(
						width: 400,
						child: page,
					)
				),
				/* Card(
					color: Colors.black26,
					child: SizedBox(
						width: 400,
						child: Column(
							children: [
								Container(
									alignment: Alignment.center,
									padding: const EdgeInsets.all(8),
									child: Text(
										"Equipages",
										style: TextStyle(
											fontSize: 20
										)
									),
								),
								Divider(),
								ListTile(
									title: Text("203 Silas Pockendahl"),
									subtitle: Text("Aidah OX"),
								),
								ListTile(
									title: Text("203 Silas Pockendahl"),
									subtitle: Text("Aidah OX"),
								),
								ListTile(
									title: Text("203 Silas Pockendahl"),
									subtitle: Text("Aidah OX"),
								),
							],
						)
					)
				),
				Spacer(),
				Card(
					color: Colors.black26,
					child: SizedBox(
						width: 250,
						child: Column(
							children: [
								Container(
									alignment: Alignment.center,
									padding: const EdgeInsets.all(8),
									child: Text(
										"Equipages",
										style: TextStyle(
											fontSize: 20
										)
									),
								),
								Divider(),
								ListTile(
									title: Text("203 Silas Pockendahl"),
									subtitle: Text("Aidah OX"),
								),
								Spacer(),
								Expanded(
									child: 
									Numpad(
										onAccept: (_) {},
									)
								)
							]
						)
					)
				) */
			],
		);
}
