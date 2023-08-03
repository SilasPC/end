
import 'package:common/Equipe.dart';
import 'package:flutter/material.dart';

import 'util/input_modals.dart';

class AdminPage extends StatelessWidget {
	
	const AdminPage({super.key});

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: const Text("Server administration"),
			),
			body: ListView(
				children: [
					ListTile(
						title: const Text("Reset to init"),
					),
					ListTile(
						title: const Text("Load model..."),
						onTap: () => loadModel(context),
					),
				],
			),
		);

		Future<void> loadModel(BuildContext context) async {
			var meets = await loadRecentMeetings();
			showChoicesModal(
				context,
				["DEMO"]..addAll(meets.map((e) => e.name)),
				(name) async {
					if (name == "DEMO") {
						return;
					}
					int id = meets.firstWhere((e) => e.name == name).id;
					return;
				}
			);
		}

}
