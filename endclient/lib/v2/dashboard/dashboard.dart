import 'package:esys_client/consts.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:esys_client/v2/app_bars/nav_side_bar.dart';
import 'package:esys_client/v2/views/glob.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      view: SecretaryView(key: GlobalKey()),
    ),
    NavItem(
      icon: Icons.data_array,
      label: "Data",
      view: DataView(key: GlobalKey()),
    ),
    NavItem(
      icon: Icons.flag,
      label: "Depature gate",
      view: DepartureView(key: GlobalKey()),
    ),
    NavItem(
      icon: Icons.flag,
      label: "Arrival gate",
      view: ArrivalView(key: GlobalKey()),
    ),
    NavItem(
      icon: Icons.flag,
      label: "Vet gate",
      view: VetView(key: GlobalKey()),
    ),
    NavItem(
      icon: Icons.monitor_heart,
      label: "Exam gate",
      view: ExamGateView(key: GlobalKey()),
    ),
    NavItem(
        icon: Icons.settings,
        label: "Settings",
        view: SettingsView(key: GlobalKey())),
  ];

  NavItem currentView = navItems.first;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    bool narrow = size.width < 800;
    return Provider.value(
      value: UI(narrow, navItems, currentView, navigate),
      child: Material(
        child: narrow ? narrowLayout() : wideLayout(),
      ),
    );
  }

  Widget wideLayout() => Row(
        children: [
          NavSidebar(
            navItems: navItems,
            itemSelected: navigate,
            currentItem: currentView,
          ),
          Expanded(
              child: Container(
                  decoration: backgroundGradient, child: currentView.view)),
        ],
      );

  void navigate(NavItem newView) => setState(() {
        currentView = newView;
      });

  Widget narrowLayout() {
    var color = BottomNavigationBarTheme.of(context).backgroundColor;
    return Scaffold(
      /* bottomNavigationBar: BottomNavigationBar(
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
			), */
      drawerEnableOpenDragGesture: false,
      drawer: NavSidebar(
        noClock: true,
        navItems: navItems,
        itemSelected: (newView) => setState(() {
          currentView = newView;
        }),
        currentItem: currentView,
      ),
      // appBar: TopBar(),
      body: Container(
        decoration: backgroundGradient,
        child: currentView.view,
      ),
    );
  }
}
