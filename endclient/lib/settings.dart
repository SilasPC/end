
import 'dart:async';
import 'dart:io';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:common/Equipe.dart';
import 'package:common/models/demo.dart';
import 'package:common/util.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
						title: const Text("Manual sync"),
						onTap: () => model.manualSync(),
					),
					ListTile(
						leading: const Icon(Icons.sync),
						title: const Text("Resync"),
						onTap: () => model.resetSync(),
					),
					ListTile(
						leading: const Icon(Icons.bluetooth),
						title: const Text("Bluetooth sync"),
						onTap: () {
							btSync();
						},
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
							title: const Text("Reset remote"),
							onTap: () => context.read<LocalModel>().connection.sendReset(),
						),
						ListTile(
							title: const Text("Load model..."),
							onTap: () => loadModel(context),
						),
					],
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
				await m.reset();
				if (name == "DEMO") {
					await m.addSync(demoInitEvent(nowUNIX()+300));
				} else {
					var meet = meets.firstWhere((e) => e.name == name);
					var evs = await meet.loadEvents();
					await m.addSync(evs);
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

	static void btSync() async {
		var bt = BluetoothClassic();
		if (!await bt.initPermissions()) {
			print("no perm");
			return;
		}
		List<Device> devs = [];
		bt.onDeviceDiscovered().listen((dev) {
			devs.add(dev);
		});
		await bt.startScan();
		await delay(const Duration(seconds: 5));
		await bt.stopScan();
		var dev = devs.first;
		print("${dev.name}");
		await bt.connect(dev.address, SERIAL_UUID);		
		print("connected");
		await bt.disconnect();
		print("disconnected");
	}

}

const SERIAL_UUID = "00001101-0000-1000-8000-00805f9b34fb";
