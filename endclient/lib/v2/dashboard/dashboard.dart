
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:ffi';

import 'package:esys_client/v2/dashboard/overview.dart';
import 'package:esys_client/v2/dashboard/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {

	const Dashboard({super.key});

	@override
	State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

	Widget view = OverviewView();

	@override
	Widget build(BuildContext context) {
		var size = MediaQuery.sizeOf(context);
		bool narrow = size.width < 800;
		return Provider.value(
			value: narrow ? DashLayout.narrow : DashLayout.wide,
			child: narrow ? narrowLayout() : wideLayout(),
		);
	}
	
	Widget wideLayout() =>
		Material(
			child: Row(
				children: [
					Container(
						width: 200,
						color: Colors.black26,
						child: DashboardMenu(
							currentView: view.runtimeType,
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
		
	Widget narrowLayout() =>
		Scaffold(
			drawer: Drawer(
				child: DashboardMenu(
					currentView: view.runtimeType,
					viewSelected: (newView) => setState(() {
						view = newView;
					}),
				),
			),
			body: view,
		);
}

enum DashLayout {
	wide,
	narrow
}
