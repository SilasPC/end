
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
					ListTile(
						leading: const Icon(Icons.bluetooth),
						title: const Text("Bluetooth sync"),
						onTap: () {}, // TODO: add bluetooth sync
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
						title: const Text("Reset remote model"),
						onTap: () {}
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
			// ignore: use_build_context_synchronously
			showChoicesModal(
				context,
				["DEMO"]..addAll(meets.map((e) => e.name)),
				(name) async {
					m.reset();
					if (name == "DEMO") {
						m.add(demoInitEvent(nowUNIX()+300));
						return;
					}
					var meet = meets.firstWhere((e) => e.name == name);
					var evs = await loadModelEvents(meet.id);
					m.add(evs);
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
