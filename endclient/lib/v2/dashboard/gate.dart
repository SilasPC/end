
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/util/numpad.dart';
import 'package:flutter/material.dart';

class GateView extends StatelessWidget {
	const GateView({super.key});

	@override
	Widget build(BuildContext context) =>
		Row(
			children: [
				Card(
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
				)
			],
		);


}
