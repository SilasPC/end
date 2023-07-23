
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'LocalModel.dart';
import 'gates/arrival.dart';
import 'gates/departure.dart';
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
	];
	static const List<Widget> pages = [
		SecretaryPage(),
		DeparturePage(),
		ExamPage(),
		VetPage(),
		ArrivalPage(),
	];

	List<String> items = ["a","b","c"];
	TextEditingController txtCtrl =
		TextEditingController(text: LocalModel.instance.author);

	@override
	void initState() {
		super.initState();
	}

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: const Text("Endurance prototype"),
				actions: const [ConnectionIndicator()],
			),
			body: Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						TextField(
							controller: txtCtrl,
							onSubmitted: (val) {
								LocalModel.instance.author = val;
							},
						),
						ElevatedButton(
							onPressed: () {
								/* Locally(
									context: context,
									pageRoute: MaterialPageRoute(builder: (_) => const LandingPage(),),
									payload: "wutisdis",
									appIcon: "",
								).show(title: "I am a title", message: "I am a message"); */
							},
							child: const Text("Notification"),
						),
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
