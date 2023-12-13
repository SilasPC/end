
import 'package:esys_client/consts.dart';
import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:esys_client/v2/dashboard/side_bar.dart';
import 'package:esys_client/v2/dashboard/views/glob.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {

	const Dashboard({super.key});

	@override
	State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

	static List<NavItem> navItems = [
		NavItem(
			icon: Icons.post_add,
			label: "Secretary",
			view: SecretaryView(),
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

	NavItem currentView = navItems.first;

	@override
	Widget build(BuildContext context) {
		var size = MediaQuery.sizeOf(context);
		bool narrow = size.width < 800;
		return Material(
			child: narrow ? narrowLayout() : wideLayout(),
		);
	}
	
	Widget wideLayout() =>
		Row(
			children: [
				SideBar(
					navItems: navItems,
					itemSelected: (newView) => setState(() { currentView = newView; }),
					currentItem: currentView,
				),
				Expanded(
					child: Container(
						decoration: backgroundGradient,
						child: currentView.view
					)
				),
			],
		);
		
	Widget narrowLayout() {
		var color = BottomNavigationBarTheme.of(context).backgroundColor;
		return Scaffold(
			bottomNavigationBar: BottomNavigationBar(
				currentIndex: navItems.indexOf(currentView),
				items: [
					for (var navItem in navItems)
					BottomNavigationBarItem(
						icon: Icon(navItem.icon),
						label: navItem.label,
						backgroundColor: color,
					),
				],
				onTap: (index) => setState(() { currentView = navItems[index]; })
			),
			drawerEnableOpenDragGesture: false,
			drawer: SideBar(
				noClock: true,
				navItems: navItems,
				itemSelected: (newView) => setState(() { currentView = newView; }),
				currentItem: currentView,
			),
			appBar: AppBar(
				title: Container(
					height: 65,
					padding: const EdgeInsets.only(bottom: 6),
					child: FittedBox(
						child: TextClock(),
					),
				),
				actions: const [
					ConnectionIndicator2(
						iconOnly: true,
					)
				],
			),
			body: Container(
				decoration: backgroundGradient,
				child: currentView.view,
			),
		);
	}


}
