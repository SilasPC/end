
import 'package:common/Equipe.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';

import 'LocalModel.dart';
import 'util/input_modals.dart';

class SettingsPage extends StatefulWidget {

	const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

	final TextEditingController _txtCtrl = TextEditingController(text: LocalModel.instance.connection.socketAddress); 

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: const Text("Settings"),
				actions: const [
					ConnectionIndicator(),
				],
			),
			body: ListView(
				children: [
					ListTile(
						title: TextField(
							decoration: const InputDecoration(
								label: Text("Server address"),
							),
							controller: _txtCtrl,
							onSubmitted: (value) {
								LocalModel.instance.connection.socketAddress = value;
							},
						)
					),
					ListTile(
						leading: const Icon(Icons.sync),
						title: const Text("Resync"),
						onTap: () => LocalModel.instance.resetSync(),
					),
					const ListTile(
						title: Text("Administration"),
						dense: true,
					),
					ListTile(
						title: const Text("Reset remote model"),
						onTap: () {}
					),
					ListTile(
						title: const Text("Load remote model..."),
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
