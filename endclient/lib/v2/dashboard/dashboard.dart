
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/v2/dashboard/side_menu.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {

	const Dashboard({super.key});

	@override
	State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

	Widget? view = DashboardMenu.defaultView();

	@override
	Widget build(BuildContext context) =>
		Material(
			child: Row(
				children: [
					Container(
						width: 200,
						color: Colors.black26,
						child: DashboardMenu(
							viewSelected: (newView) => setState(() {
								view = newView;
							}),
						),
					),
					if (view case Widget view)
					Expanded(
						child: view,
					),
				],
			)
		);
}
