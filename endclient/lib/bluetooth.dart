
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock/wakelock.dart';

class BluetoothPage extends StatefulWidget {
	const BluetoothPage({super.key});

	@override
	BluetoothPageState createState() => BluetoothPageState();

}

class Device {
	final String id;
	final String userName;
	final String service;
	Status? status;

	Device(this.id, this.userName, this.service);
}

class BluetoothPageState extends State<BluetoothPage> {

	late final Nearby _bt;
	Map<String, Device> _devs = {};
	StreamSubscription? _rcv, _chg;

	String _data = "";

	@override
	void initState() {
		super.initState();
		_setup();
		Wakelock.enable();
	}

	void _setup() async {
		try {

			if (!await Permission.location.isGranted) {
				if (!(await Permission.location.request()).isGranted) {
					print("no loc perm");
				}
			}

			// location enable dialog
			// await Location.instance.requestService()

			// Bluetooth permissions
			bool granted = !(await Future.wait([
				Permission.bluetooth.isGranted,
				Permission.bluetoothAdvertise.isGranted,
				Permission.bluetoothConnect.isGranted,
				Permission.bluetoothScan.isGranted,
			])).any((element) => false);
			if (!granted) {
				var res = await [
					Permission.bluetooth,
					Permission.bluetoothAdvertise,
					Permission.bluetoothConnect,
					Permission.bluetoothScan
				].request();
				if (res.values.any((e) => !e.isGranted)) {
					print("no bt perm");
				}
			}

			if (!await Permission.nearbyWifiDevices.isGranted) {
				if (!(await Permission.nearbyWifiDevices.request()).isGranted) {
					print("no nbwifi perm");
				}
			}

			if (!await Location.instance.serviceEnabled()) {
				if (!await Location.instance.requestService()) {
					print("no loc serv");
				}
			}

			_bt = Nearby();
			var suc = await _bt.startAdvertising(
				Platform.localHostname,
				Strategy.P2P_CLUSTER,
				onConnectionInitiated: (id, info) {
					print("init $id");
				},
				onConnectionResult: (id, state) {
					print("res $id $state");
					//_devs[id]?.status = state;
				},
				onDisconnected: (id) {
					print("disc $id");
					//_devs.remove(id);
				},
				serviceId: "com.example.endclient",
			);
			if (!suc) print("fuck ad");
			suc = await _bt.startDiscovery(
				Platform.localHostname,
				Strategy.P2P_CLUSTER,
				onEndpointFound: (id, name, sid) {
					setState(() {
						_devs[id] = Device(id, name, sid);
					});
				},
				onEndpointLost: (id) {
					setState(() {
						_devs.remove(id);
					});
				},
				serviceId: "com.example.endclient",
			);
			if (!suc) print("fuck dis");
		} catch (e, st) {
			print(e);
			print(st);
		}
	}

	@override
	void dispose() {
		Wakelock.disable();
		_bt
			..stopAdvertising()
			..stopDiscovery();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) =>
		Scaffold(
			appBar: AppBar(
				title: const Text("Nearby"),
			),
			body: ListView(
				children: [
					ListTile(
						title: Text(_data),
						onLongPress: () {setState(() {_data = "";});},
					),
					for (var dev in _devs.values)
					ListTile(
						title: Text("${dev.userName}: ${dev.service}"),
						trailing: ElevatedButton(
							child: Text(dev.status?.name ?? "UNKNOWN"),
							onPressed: () async {
								
							},
						),
						onTap: () async {
							
						},
					)
				]
			),
		);


}
