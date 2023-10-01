
// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/util.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum DevStatus {
	CONNECTED,
	AVAILABLE,
	UNAVAILABLE,
}

// FIXME: race conditions
class Device {
	
	final NearbyMan _man;
	final String id;
	final String name;

	ValueNotifier<DevStatus> status = ValueNotifier(DevStatus.AVAILABLE);

	bool get unavailable => status.value == DevStatus.UNAVAILABLE;
	bool get available => status.value != DevStatus.UNAVAILABLE;
	bool get connected => status.value == DevStatus.CONNECTED;
	bool get disconnected => status.value != DevStatus.CONNECTED;
	
	Device(this._man, this.id, this.name);

	Future<bool> connect() async {
		if (unavailable) return false;
		if (connected) return true;
		return _man._bt.requestConnection(
			_man.localName,
			id,
			onConnectionInitiated: _man._onInit,
			onConnectionResult: _man._onRes, 
			onDisconnected: _man._onDisconnect, 
		);
	}
	Future<void> disconnect() async {
		if (disconnected) return;
		await _man._bt.disconnectFromEndpoint(id);
		if (available) {
			status.value = DevStatus.AVAILABLE;
		}
	}

	Future<bool> transmit() async {
		if (disconnected) return false;
		await _man._bt.sendBytesPayload(id, Uint8List.fromList([42,43,44]));
		return true;
	}

	final StreamController<void> _stream = StreamController.broadcast();
	Stream<void> get dataStream => _stream.stream;

}

class NearbyMan {

	static const String SERVICE_ID = "com.example.endclient";

	late final Nearby _bt;
	final Map<String, Device> _devs = {};
	final String localName = Platform.localHostname;

	ValueNotifier<List<Device>> devices = ValueNotifier([]);

	bool _autoConnect = false;
	bool get autoConnect => _autoConnect;
	set autoConnect (val) {
		if (val && val != _autoConnect) {
			for (var dev in _devs.values) {
				if (dev.status.value == DevStatus.AVAILABLE) {
					dev.connect();
				}
			}
		}
		_autoConnect = val;
	}

	NearbyMan() {
		_getPerms().then((_) => _setup());
	}

	void dispose() {
		_bt..stopAdvertising()
			..stopDiscovery();
	}

	Future<void> _setup() async {
		
		_bt = Nearby();

		await _bt.stopDiscovery();
		await _bt.stopAdvertising();
		await _bt.stopAllEndpoints();

		var suc = await _bt.startAdvertising(
			localName,
			Strategy.P2P_CLUSTER,
			onConnectionInitiated: _onInit,
			onConnectionResult: _onRes,
			onDisconnected: _onDisconnect,
			serviceId: SERVICE_ID,
		);
		if (!suc) print("fuck ad");

		suc = await _bt.startDiscovery(
			localName,
			Strategy.P2P_CLUSTER,
			onEndpointFound: _onFound,
			onEndpointLost: _onLost,
			serviceId: SERVICE_ID,
		);
		if (!suc) print("fuck dis");

		print("ok");
	}

	static Future<void> _getPerms() async {
		if (!await Permission.location.isGranted) {
			if (!(await Permission.location.request()).isGranted) {
				print("no loc perm");
			}
		}

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
				print("no _bt perm");
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
	}

	void _onFound(String id, String name, String sid) {
		if (sid != SERVICE_ID) return;
		print("found $id $name $sid");
		var dev = _dev(id, name);
		if (dev.disconnected) {
			dev.status.value = DevStatus.AVAILABLE;
		}
		if (_autoConnect) {
			dev.connect();
		}
	}
	
	void _onLost(String? id) {
		print("lost $id");
		_devs[id]?.status.value = DevStatus.UNAVAILABLE;
	}

	void _onInit(String id, ConnectionInfo info) async {
		var dev = _dev(id, "?");
		await _bt.acceptConnection(
			id,
			onPayLoadRecieved: (id, data) {
				print("rcv $id ${data.type} ${maybe(data.bytes, (d) => utf8.decode(d, allowMalformed: true))}");
				// dev._stream.add();
			}
		);
	}

	void _onRes(String id, Status state) {
		print("res $id $state");
		var dev = _devs[id]!;
		switch (state) {
			case Status.CONNECTED:
				dev.status.value = DevStatus.CONNECTED;
			case Status.ERROR:
			case Status.REJECTED:
				dev.status.value = DevStatus.AVAILABLE;
		}
	}

	void _onDisconnect(String id) {
		print("disc $id");
		_devs[id]!.status.value = DevStatus.AVAILABLE;
	}

	Device _dev(String id, String name) =>
		_devs.putIfAbsent(
			id,
			() {
				var dev = Device(this, id, name);
				devices.value = [..._devs.values, dev];
				return dev;
			}
		);

}
