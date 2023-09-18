
import 'package:flutter/material.dart';

import 'settings.dart';
import 'gates/departure.dart';
import 'util/connection_indicator.dart';
import 'gates/arrival.dart';
import 'gates/exam.dart';
import 'gates/vet.dart';
import 'secretary/secretary.dart';

class LandingPage extends StatefulWidget {
	const LandingPage({super.key});

	@override
	LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {

	static const List<Text> buttons = [
		Text("Secretary"),
		Text("Departure"),
		Text("Exam"),
		Text("Vet"),
		Text("Arrival"),
		Text("Settings"),
	];
	static const List<Widget> pages = [
		SecretaryPage(),
		DeparturePage(),
		ExamPage(),
		VetPage(),
		ArrivalPage(),
		SettingsPage(),
	];

	@override
	void initState() {
		super.initState();
	}

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: const Text("Endurance"),
				actions: const [ConnectionIndicator()],
			),
			body: Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						for (int i = 0; i < buttons.length; i++)
						buildLinkButton(i),
					],
				)
			)
		);

	Widget buildLinkButton(int i) =>
		ElevatedButton(
			onPressed: () =>
				Navigator.push(
					context,
					MaterialPageRoute(builder: (ctx) => pages[i])
				),
			child: buttons[i],
		);

}
