
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:esys_client/nearby.dart';
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

	late final NearbyMan man;
	List<Device> devs = [];

	@override
	void initState() {
		super.initState();
		_setup();
		Wakelock.enable();
	}

	void print(String msg) {
		ScaffoldMessenger.of(context).showSnackBar(SnackBar(
			content: Text(msg)));
	}

	bool isSetup = false;
	void _setup() async {
		isSetup = true;
		man = NearbyMan();
	}

	@override
	void dispose() {
		Wakelock.disable();
		man.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		if (!isSetup) _setup();
		return Scaffold(
			appBar: AppBar(
				title: const Text("Nearby"),
			),
			body: AnimatedBuilder(
				animation: man.devices,
				builder: (context, _) =>
					ListView(
						children: [
							ListTile(
								title: const Text("Autoconnect"),
								trailing: Switch(
									value: man.autoConnect,
									onChanged: (val) {
										setState(() {
											man.autoConnect = val;
										});
									},
								)
							),
							for (var dev in man.devices.value)
							ListTile(
								title: Text(dev.name),
								subtitle: Text(dev.id),
								onTap: () {
									dev.transmit();
								},
								trailing: ElevatedButton(
									child: AnimatedBuilder(
										animation: dev.status,
										builder: (context, _) => Text(dev.status.value.name),
									),
									onPressed: () {
										switch (dev.status.value) {
											case DevStatus.CONNECTED:
												dev.disconnect();
												break;
											case DevStatus.AVAILABLE:
												dev.connect();
												break;
											default:
												break;
										}
									},
								),
							)
						]
					),
			)
		);
	}

}
