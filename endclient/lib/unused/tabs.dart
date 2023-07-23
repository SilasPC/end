
import 'package:esys_client/gates/departure.dart';
import 'package:flutter/material.dart';

import '../gates/exam.dart';
class TabsPage extends StatefulWidget {
	@override
	_TabsPageState createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
	int _currentIndex=0;
	final List _screens = const [ExamPage(), DeparturePage()];

	void _updateIndex(int value) {
	 setState(() {
		_currentIndex = value;
	 });
	}

	@override
	Widget build(BuildContext context) {
	 return Scaffold(
		body: _screens[_currentIndex],
		bottomNavigationBar: BottomNavigationBar(
			type: BottomNavigationBarType.fixed,
			currentIndex: _currentIndex,
			onTap: _updateIndex,
			selectedItemColor: Colors.blue[700],
			selectedFontSize: 13,
			unselectedFontSize: 13,
			iconSize: 30,
			items: [
			 BottomNavigationBarItem(
				label: "Examination",
				icon: Icon(Icons.monitor_heart),
			 ),
			 BottomNavigationBarItem(
				label: "Departure",
				icon: Icon(Icons.flag),
			 ),
			],
		),
	 );
	}


}
