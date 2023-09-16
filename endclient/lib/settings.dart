
import 'dart:io';

import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/util.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocalModel.dart';
import 'util/input_modals.dart';

class SettingsPage extends StatefulWidget {

	const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

	final TextEditingController _servAddr = TextEditingController(); 
	final TextEditingController _author = TextEditingController();

	late Settings set;
	bool isInit = false;

	@override
	Widget build(BuildContext context) {
		if (!isInit) {
			set = context.watch<Settings>().clone();
			_servAddr.text = set.serverURI;
			_author.text = set.author;
			isInit = true;
		}
		var model = context.read<LocalModel>();
		return Scaffold(
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
								model.connection.socketAddress = value;
							},
						)
					),
					ListTile(
						title: TextField(
							decoration: const InputDecoration(
								label: Text("Author"),
							),
							controller: _author,
							onSubmitted: (val) => setState((){
								set.author = val;
								set.save();
							}),
						)
					),
					ListTile(
						leading: const Icon(Icons.admin_panel_settings),
						title: const Text("Enable advanced mode"),
						trailing: Switch(
							value: set.showAdmin,
							onChanged: (val) => setState((){
								set.showAdmin = val;
								set.save();
							}),
						),
					),
					ListTile(
						leading: const Icon(Icons.settings_backup_restore),
						title: const Text("Reset to defaults"),
						onTap: () => setState((){
							set..setDefaults()..save();
						}),
					),
					ListTile(
						leading: const Icon(Icons.sync),
						title: const Text("Resync"),
						onTap: () => model.resetSync(),
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
						onTap: () => context.read<LocalModel>().connection.sendReset(),
					),
					ListTile(
						title: const Text("Load model..."),
						onTap: () => loadModel(context),
					),
				],
			),
		);
	}

		static Future<void> loadModel(BuildContext context) async {
			var m = context.read<LocalModel>();
			var meets = await loadRecentMeetings();
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
		// CHECK: android saving works
		var m = context.read<LocalModel>();
		var sm = ScaffoldMessenger.of(context);
		var dir = await getApplicationDocumentsDirectory();
		var file = File("${dir.path}/endurance.csv");
		var data = m.model.toResultCSV();
		print(file);
		await file.writeAsString(data);
		sm.showSnackBar(const SnackBar(
			content: Text("Saved CSV results"),
		));
	}
}
