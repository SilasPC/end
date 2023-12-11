

import 'package:esys_client/consts.dart';
import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/v2/dashboard/arrival_view.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:esys_client/v2/dashboard/data_view.dart';
import 'package:esys_client/v2/dashboard/departure_view.dart';
import 'package:esys_client/v2/dashboard/exam_gate/exam_gate_view.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:esys_client/v2/dashboard/overview.dart';
import 'package:esys_client/v2/dashboard/side_menu.dart';
import 'package:esys_client/v2/dashboard/vet_view.dart';
import 'package:flutter/material.dart';

import 'settings_view.dart';

class Dashboard extends StatefulWidget {

	const Dashboard({super.key});

	@override
	State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

	static List<NavItem> navItems = [
		NavItem(
			icon: Icons.grid_view,
			label: "Overview",
			view: OverviewView(),
		),
		const NavItem(
			icon: Icons.data_array,
			label: "Data",
			view: DataView(),
		),
		const NavItem(
			icon: Icons.flag,
			label: "Depature gate",
			view: DepartureView(),
		),
		const NavItem(
			icon: Icons.flag,
			label: "Arrival gate",
			view: ArrivalView(),
		),
		const NavItem(
			icon: Icons.flag,
			label: "Vet gate",
			view: VetView(),
		),
		const NavItem(
			icon: Icons.monitor_heart,
			label: "Exam gate",
			view: ExamGateView(),
		),
		const NavItem(
			icon: Icons.settings,
			label: "Settings",
			view: SettingsView()
		),
	];

	int currentView = 0;

	@override
	Widget build(BuildContext context) {
		var size = MediaQuery.sizeOf(context);
		bool narrow = size.width < 800;
		return /* Provider.value(
			value: narrow ? DashLayout.narrow : DashLayout.wide,
			child:  */narrow ? narrowLayout() : wideLayout()/* ,
		) */;
	}
	
	Widget wideLayout() =>
		Material(
			child: Row(
				children: [
					DashboardMenu(
						navItems: navItems,
						itemSelected: (newView) => setState(() { currentView = newView; }),
						currentItem: currentView,
					),
					Expanded(
						child: Container(
							decoration: backgroundGradient,
							child: navItems[currentView].view
						)
					),
				],
			)
		);
		
	Widget narrowLayout() {
		var color = BottomNavigationBarTheme.of(context).backgroundColor;
		return Scaffold(
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: currentView,
				items: [
					for (var navItem in navItems)
					BottomNavigationBarItem(
						icon: Icon(navItem.icon),
						label: navItem.label,
						backgroundColor: color,
					),
				],
				onTap: (index) => setState(() { currentView = index; })
			),
			body: Column(
				children: [
					topBar(),
					Expanded(
						child: Container(
							decoration: backgroundGradient,
							child: navItems[currentView].view,
						),
					)
				]
			)
		);
	}

	Widget topBar() =>
		Container(
			padding: const EdgeInsets.symmetric(
				horizontal: 12
			),
			height: 65,
			color: Theme.of(context).canvasColor,
			child: Row(
				children: [
					Container(
						height: 65,
						padding: const EdgeInsets.only(bottom: 6),
						child: FittedBox(
							fit: BoxFit.fitHeight,
							child: TextClock(),
						),
					),
					const Spacer(),
					IconButton(
						icon: const Icon(Icons.logout),
						onPressed: () {
							Navigator.of(context).pop();
						},
					),
					const SizedBox(width: 10,),
					const ConnectionIndicator2(
						iconOnly: true,
					)
				],
			),
		);

}
