
import 'dart:async';
import 'dart:io';
import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/util.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
      var session = context.watch<SessionState>();
		return ListView(
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
					leading: const Icon(Icons.notifications),
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
					leading: const Icon(Icons.zoom_in),
					title: const Text("Large UI"),
					trailing: Switch(
						value: set.largeUI,
						onChanged: (val) => setState((){
							set.largeUI = val;
							set.save();
						}),
					),
				),
				ListTile(
					leading: const Icon(Icons.screenshot_outlined),
					title: const Text("Gates keep screen alive"),
					trailing: Switch(
						value: set.useWakeLock,
						onChanged: (val) => setState((){
							set.useWakeLock = val;
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
					onTap: () => model.resetModel(),
				),
				ListTile(
					leading: const Icon(Icons.data_array),
					title: const Text("Save CSV"),
					onTap: () => saveCSV(context),
				),
				if (set.showAdmin)
				...[
					const ListTile(
						title: Text("Administration"),
						dense: true,
					),
					ListTile(
						leading: const Icon(Icons.cancel),
						title: const Text("New session"),
						subtitle: Text("Current: ${session.sessionId}"),
						onTap: () {
							if (set.autoYield) {
								setState((){
									set..autoYield = false
										..save();
								});
							}
							session.reset();
						}
					),
					ListTile(
						leading: const Icon(Icons.cloud_upload),
						title: const Text("Upload session"),
						subtitle: conn.sessionId != null ? Text("Remote: ${conn.sessionId}") : null,
						onTap: () => conn.yieldRemote(),
					),
					ListTile(
						leading: const Icon(Icons.download),
						title: const Text("Load model..."),
						onTap: loadModel,
					),
				],
				const ListTile(
					title: Text("About"),
					dense: true,
				),
				if (_loadPackageInfo() case PackageInfo info) ...[
					ListTile(
						title: const Text("Version"),
						subtitle: Text("${info.version}+${info.buildNumber}"),
					)
				]
			],
		);
	}

	PackageInfo? _packageInfo;
	PackageInfo? _loadPackageInfo() {
		if (_packageInfo != null) return _packageInfo;
		PackageInfo.fromPlatform()
			.then((i) => setState(() => _packageInfo = i))
			.catchError((_) {});
		return null;
	}

	Future<void> loadModel() async {
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
