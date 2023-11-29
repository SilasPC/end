
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/consts.dart';
import 'package:esys_client/v2/dashboard/data_view.dart';
import 'package:esys_client/v2/dashboard/gate.dart';
import 'package:esys_client/v2/dashboard/overview.dart';
import 'package:esys_client/v2/dashboard/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_view.dart';

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
						color: black27,
						child: DashboardMenu(
							currentView: view.runtimeType,
							viewSelected: (newView) => setState(() {
								view = newView;
							}),
						),
					),
					Expanded(
						child: Container(
							decoration: backgroundGradient,
							child: view
						)
					),
				],
			)
		);

	int _cur = 0;
		
	Widget narrowLayout() {
		var color = BottomNavigationBarTheme.of(context).backgroundColor;
		return Scaffold(
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: _cur,
				items: [
					BottomNavigationBarItem(
						icon: Icon(Icons.grid_view),
						label: "Overview",
						backgroundColor: color,
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.data_array),
						label: "Data",
						backgroundColor: color,
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.flag),
						label: "Gates",
						backgroundColor: color,
					),
					BottomNavigationBarItem(
						icon: Icon(Icons.settings),
						label: "Settings",
						backgroundColor: color,
					)
				],
				onTap: (index) {
					setState(() {
						_cur = index;
						view = switch (index) {
							0 => OverviewView(),
							1 => DataView(),
							2 => GateView(),
							3 => SettingsView(),
							_ => view
						};
					});
				},
			),
			body: Container(
				decoration: backgroundGradient,
				child: view,
			)
		);
	}

}

enum DashLayout {
	wide,
	narrow
}
