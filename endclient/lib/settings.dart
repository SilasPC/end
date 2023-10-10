
import 'dart:async';
import 'dart:io';
import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/util.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/local_model/states.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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

	@override
	void initState() {
		super.initState();
		set = context.read<Settings>().clone();
		_servAddr.text = set.serverURI;
		_author.text = set.author;
	}

	@override
	Widget build(BuildContext context) {
		var model = context.read<LocalModel>();
		var conn = context.watch<ServerConnection>();
		context.watch<PeerStates>();
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
							onSubmitted: (val) {
								set.serverURI = val;
								set.save();
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
						title: const Text("Enable notifications"),
						trailing: Switch(
							value: set.sendNotifs,
							onChanged: (val) => setState((){
								set.sendNotifs = val;
								set.save();
							}),
						),
					),
					ListTile(
						leading: const Icon(Icons.cloud_download),
						title: const Text("Auto yield"),
						trailing: Switch(
							value: set.autoYield,
							onChanged: (val) => setState((){
								set..autoYield = val..save();
							}),
						),
					),
					ListTile(
						leading: const Icon(Icons.groups),
						title: const Text("Use P2P"),
						trailing: Switch(
							value: set.useP2P,
							onChanged: (val) => setState((){
								set..useP2P = val..save();
							}),
						),
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
						onTap: () => model.manager.resetModel(),
					),
					ListTile(
						leading: const Icon(Icons.data_array),
						title: const Text("Save CSV"),
						onTap: () => saveCSV(context),
					),
					if (set.author.startsWith("admin"))
					...[
						const ListTile(
							title: Text("Administration"),
							dense: true,
						),
						ListTile(
							leading: const Icon(Icons.cancel),
							title: const Text("New session"),
							subtitle: Text("Current: ${model.manager.sessionId}"),
							onTap: () {
								if (set.autoYield) {
									setState((){
										set..autoYield = false
											..save();
									});
								}
								model.manager.resetSession();
							}
						),
						ListTile(
							leading: const Icon(Icons.cloud_upload),
							title: const Text("Yield remote"),
							subtitle: conn.sessionId != null ? Text("Remote: ${conn.sessionId}") : null,
							onTap: () => conn.yieldRemote(),
						),
						ListTile(
							leading: const Icon(Icons.download),
							title: const Text("Load model..."),
							onTap: () => loadModel(context),
						),
					],
					// UI: this has to be different
					const ListTile(
						title: Text("Peers"),
						dense: true,
					),
					for (var p in model.manager.peers)
					ListTile(
						title: Text(p.id ?? "?"),
						subtitle: Text(!p.connected ? "-" : p.state.name),
						onTap: () {
							model.manager.yieldTo(p);
						},
					)
				],
			),
		);
	}

	static Future<void> loadModel(BuildContext context) async {
		var m = context.read<LocalModel>();
		var meets = await EquipeMeeting.loadRecent();
		// ignore: use_build_context_synchronously
		showChoicesModal(
			context,
			["DEMO", ...meets.map((e) => e.name)],
			(name) async {
				if (name == "DEMO") {
					await m.addSync(demoInitEvent(nowUNIX()+300));
				} else {
					var meet = meets.firstWhere((e) => e.name == name);
					try {
						var evs = await meet.loadEvents();
						await m.addSync(evs);						
					} catch (e, s) {
						print(e);
						print(s);
						ScaffoldMessenger.of(context)
							.showSnackBar(const SnackBar(
								content: Text("Failed to load from Equipe"),
							));
					}
				}
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
