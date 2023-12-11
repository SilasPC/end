

import 'dart:io';

import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/local_model/local_model.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

// UI: flex layout
class SettingsView extends StatefulWidget {

	final MainAxisAlignment mainAxisAlignment;
	const SettingsView({super.key, this.mainAxisAlignment = MainAxisAlignment.start});

	@override
	State<SettingsView> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsView> {
	
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
		// IGNORED: CHECK: android saving works
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

	@override
	Widget build(BuildContext context) {
		var model = context.read<LocalModel>();
		var conn = context.watch<ServerConnection>();
      var session = context.watch<SessionState>();
		return Row(
			mainAxisAlignment: widget.mainAxisAlignment,
			children: [
				Card(
					child: SizedBox(
						width: 350,
						child: ListView(
							children: [
								...cardHeader("Settings"),
								listGroupHeader("General"),
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
								/* ListTile(
									leading: const Icon(Icons.zoom_in),
									title: const Text("Large UI"),
									trailing: Switch(
										value: set.largeUI,
										onChanged: (val) => setState((){
											set.largeUI = val;
											set.save();
										}),
									),
								), */
								ListTile(
									leading: const Icon(Icons.dark_mode),
									title: const Text("Dark UI"),
									trailing: Switch(
										value: set.darkTheme,
										onChanged: (val) => setState((){
											set.darkTheme = val;
											set.save();
										}),
									),
								),
								ListTile(
									leading: const Icon(Icons.stay_current_portrait),
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
										set = set.defaults()..save();
									}),
								),
								ListTile(
									leading: const Icon(Icons.data_array),
									title: const Text("Save CSV"),
									onTap: () => saveCSV(context),
								),
								listGroupHeader("About"),
								if (_loadPackageInfo() case PackageInfo info) ...[
									ListTile(
										title: const Text("Version"),
										subtitle: Text("${info.version}+${info.buildNumber}"),
									)
								],
								ListTile(
									title: const Text("Protocol version"),
									trailing: Text(SyncProtocol.VERSION.toString()),
								),
							],
						),
					)
				),
				if (set.showAdmin)
				Card(
					child: SizedBox(
						width: 350,
						child: ListView(
							children: [
								...cardHeader("Advanced"),
								listGroupHeader("Connections"),
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
								listGroupHeader("Session"),
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
								ListTile(
									leading: const Icon(Icons.sync),
									title: const Text("Resync"),
									onTap: () => model.resetModel(),
								),
								listGroupHeader("Security"),
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
							],
						),
					),
				),
				if (set.showAdmin)
				Card(
					child: SizedBox(
						width: 350,
						child: Builder(
							builder: (context) {
								var conn = context.watch<ServerConnection>();
								var peers = context.watch<PeerStates>().peers;
								return ListView(
									children: [
										...cardHeader("Connections"),
										if (conn.peer case Peer p)
											_peerTile(p, "Server"),
										for (var p in peers)
										if (p != conn.peer)
											_peerTile(p)
									],
								);
							}
						)
					),
				)
			],
		);
	}

	Widget _peerTile(Peer p, [String? name]) =>
		ListTile(
			title: Text(name ?? p.id ?? "-"),
			// tileColor: p.connected ? Colors.green : Colors.red,
			subtitle: Text(p.connected ? p.state.name : "Disconnected"),
			onLongPress: () {
				if (p.connected) {
					p.disconnect();
				} else {
					p.connect();
				}
			},
			trailing: p.state.isConflict
				? IconButton(
					icon: const Icon(Icons.cloud_download),
					onPressed: () {
						context.read<LocalModel>().manager.yieldTo(p);
					},
				) : null,
		);
	
}
