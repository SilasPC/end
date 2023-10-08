
// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:common/util.dart';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'package:mutex/mutex.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum DevStatus {
	CONNECTED,
	AVAILABLE,
	UNAVAILABLE,
}

// FIXME: race conditions
class Device {
	
	final NearbyManager _man;
	final String id;
	final String name;

	ValueNotifier<DevStatus> status = ValueNotifier(DevStatus.AVAILABLE);

	bool get unavailable => status.value == DevStatus.UNAVAILABLE;
	bool get available => status.value != DevStatus.UNAVAILABLE;
	bool get connected => status.value == DevStatus.CONNECTED;
	bool get disconnected => status.value != DevStatus.CONNECTED;
	
	Device._(this._man, this.id, this.name);

	Future<bool> connect() async {
		if (unavailable) return false;
		if (connected) return true;
		return _man._bt!.requestConnection(
			_man.localName,
			id,
			onConnectionInitiated: _man._onInit,
			onConnectionResult: _man._onRes, 
			onDisconnected: _man._onDisconnect, 
		);
	}
	Future<void> disconnect() async {
		if (disconnected) return;
		await _man._bt!.disconnectFromEndpoint(id);
		if (available) {
			status.value = DevStatus.AVAILABLE;
		}
	}

	Future<bool> transmit(Uint8List data) async {
		if (disconnected) return false;
		await _man._bt!.sendBytesPayload(id, data);
		return true;
	}

	final StreamController<Uint8List> _stream = StreamController();
	Stream<void> get dataStream => _stream.stream;

}

class NearbyManager with ChangeNotifier {

	static const String SERVICE_ID = "com.example.endclient";

	late final Nearby? _bt;
	final Map<String, Device> _devs = {};
	final String localName = Platform.localHostname;
	final Mutex _mutex = Mutex();

	List<Device> devices = [];

	final bool available = Platform.isAndroid | Platform.isIOS;

	bool _enabled = true;
	bool get enabled => _enabled;
	set enabled (bool enable) {
		_mutex.protect(() async {
			if (_enabled == enable) return;
			if (enable && available) {
				await _startDiscovery();
			} else {
				await _bt?.stopDiscovery();
			}
			_enabled = enable;
		});
	}

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

	NearbyManager() {
		if (available) {
			_init();
		}
	}

	void _init() async {
		_bt = Nearby();
		_mutex.protect(() async {
			await _getPerms();
			return _setup();
		});
	}

	@override
	void dispose() {
		_bt?..stopAdvertising()
			..stopDiscovery()
			..stopAllEndpoints();
		super.dispose();
	}

	Future<bool> _startAdvertising() async =>
		await _bt?.startAdvertising(
			localName,
			Strategy.P2P_CLUSTER,
			onConnectionInitiated: _onInit,
			onConnectionResult: _onRes,
			onDisconnected: _onDisconnect,
			serviceId: SERVICE_ID,
		) ?? false;

	Future<bool> _startDiscovery() async =>
		await _bt?.startDiscovery(
			localName,
			Strategy.P2P_CLUSTER,
			onEndpointFound: _onFound,
			onEndpointLost: _onLost,
			serviceId: SERVICE_ID,
		) ?? false;

	Future<void> _setup() async {
		await _bt?.stopDiscovery();
		await _bt?.stopAdvertising();
		await _bt?.stopAllEndpoints();
		await _startAdvertising();
		if (enabled && autoConnect) {
			await _startDiscovery();
		}
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
		await _bt?.acceptConnection(
			id,
			onPayLoadRecieved: (id, data) {
				print("rcv $id ${data.type} ${data.bytes?.length}");
				if (data.bytes != null) {
					dev._stream.add(data.bytes!);
				}
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
				var dev = Device._(this, id, name);
				devices = [..._devs.values, dev];
				notifyListeners();
				return dev;
			}
		);

}
