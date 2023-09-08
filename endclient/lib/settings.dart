
import 'dart:io';

import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/util.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'LocalModel.dart';
import 'util/input_modals.dart';

class SettingsPage extends StatefulWidget {

	const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

	final TextEditingController _servAddr = TextEditingController(text: LocalModel.instance.connection.socketAddress); 
	final TextEditingController _author = TextEditingController(text: LocalModel.instance.author);

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
							controller: _servAddr,
							onSubmitted: (value) {
								LocalModel.instance.connection.socketAddress = value;
							},
						)
					),
					ListTile(
						title: TextField(
							decoration: const InputDecoration(
								label: Text("Author"),
							),
							controller: _servAddr,
							onSubmitted: (value) {
								LocalModel.instance.author = value;
							},
						)
					),
					ListTile(
						leading: const Icon(Icons.sync),
						title: const Text("Resync"),
						onTap: () => LocalModel.instance.resetSync(),
					),
					ListTile(
						leading: const Icon(Icons.bluetooth),
						title: const Text("Bluetooth sync"),
						onTap: () {}, // FEAT: add bluetooth sync
					),
					ListTile(
						leading: const Icon(Icons.data_array),
						title: const Text("Save CSV"),
						onTap: () => saveCSV(context),
					),
					const ListTile(
						title: Text("Administration"),
						dense: true,
					),
					ListTile(
						title: const Text("Reset remote"),
						onTap: () => LocalModel.instance.connection.sendReset(),
					),
					ListTile(
						title: const Text("Load model..."),
						onTap: () => loadModel(context),
					),
				],
			),
		);

		static Future<void> loadModel(BuildContext context) async {
			var meets = await loadRecentMeetings();
			var m = LocalModel.instance;
			showChoicesModal(
				context,
				["DEMO", ...meets.map((e) => e.name)],
				(name) async {
					m.reset();
					if (name == "DEMO") {
						m.addSync(demoInitEvent(nowUNIX()+300));
						return;
					}
					var meet = meets.firstWhere((e) => e.name == name);
					var evs = await loadModelEvents(meet.id);
					m.addSync(evs);
					return;
				}
			);
		}

	static Future<void> saveCSV(BuildContext context) async {
		var sm = ScaffoldMessenger.of(context);
		var dir = await getApplicationDocumentsDirectory();
		var file = File("${dir.path}/endurance.csv");
		var data = LocalModel.instance.model.toResultCSV();
		await file.writeAsString(data);
		sm.showSnackBar(const SnackBar(
			content: Text("Saved CSV results"),
		));
	}
}
