
// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:common/p2p/Manager.dart';
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
class Device extends Peer {

   @override
   bool isOutgoing() => _outGoing;
	
	final NearbyManager _man;
	final String devId;
	final String name;
   bool _outGoing;

	ValueNotifier<DevStatus> status = ValueNotifier(DevStatus.AVAILABLE);

	bool get unavailable => status.value == DevStatus.UNAVAILABLE;
	bool get available => status.value != DevStatus.UNAVAILABLE;
	// bool get connected => status.value == DevStatus.CONNECTED;
	bool get disconnected => status.value != DevStatus.CONNECTED;
	
	Device._(this._man, this.devId, this.name, this._outGoing);

   @override
	Future<bool> connect() async {
		if (unavailable) return false;
		if (connected) return true;
		return _man._bt!.requestConnection(
			_man.localName,
			devId,
			onConnectionInitiated: _man._onInit,
			onConnectionResult: _man._onRes, 
			onDisconnected: _man._onDisconnect, 
		);
	}

   @override
	Future<void> disconnect() async {
		if (disconnected) return;
		await _man._bt!.disconnectFromEndpoint(devId);
		if (available) {
			status.value = DevStatus.AVAILABLE;
		}
	}

   final Int32List _seq = Int32List.fromList([0]);
   final Map<int, Completer<List<int>?>> _completers = {};

   @override
	Future<List<int>?> send(String msg, List<int> data) async {
		if (disconnected) return null;

      var c = Completer<List<int>?>();

      var seqNr = _seq[0]++;
      _completers[seqNr] = c;
      var seqBuf = _seq.buffer.asUint8List();
		await _man._bt!.sendBytesPayload(devId, Uint8List.fromList([...seqBuf, 0, ...msg.codeUnits, 0, ...data]));

      Timer(const Duration(seconds: 5), () {
         if (!c.isCompleted) {
            c.complete(null);
         }
         _completers.remove(seqNr);
      });

		return c.future;
	}

   void _rcv(List<int> data) async {
      var seqData = data.sublist(0,4);
      var seq = Uint8List.fromList(seqData).buffer.asInt32List()[0];
      var isReply = data[4] == 1;
      if (isReply) {
         var c = _completers.remove(seq);
         if (!(c?.isCompleted ?? true)) {
            c!.complete(data.sublist(5));
         }
      } else {
         var i = data.indexOf(0, 5);
         var msg = String.fromCharCodes(data.skip(5).take(i-5));
         data = data.sublist(i+1);
         var reply = await onRecieve(msg, data);
         if (reply == null) return;
		   _man._bt!.sendBytesPayload(devId, Uint8List.fromList([
            ...seqData,
            1,
            ...reply
         ]));
      }
   }

}

class NearbyManager with ChangeNotifier {

	static const String SERVICE_ID = "com.example.endclient";

	Nearby? _bt;
	final Map<String, Device> _devs = {};
	final String localName = Platform.localHostname;
	final Mutex _mutex = Mutex();

	List<Device> devices = [];

	final bool available = Platform.isAndroid | Platform.isIOS;

	bool _enabled = false;
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

	void _onFound(String devId, String name, String sid) {
		if (sid != SERVICE_ID) return;
		print("found $devId $name $sid");
		var dev = _dev(devId, name);
		if (dev.disconnected) {
			dev.status.value = DevStatus.AVAILABLE;
		}
		if (_autoConnect) {
			dev.connect();
		}
	}
	
	void _onLost(String? devId) {
		print("lost $devId");
		_devs[devId]?.status.value = DevStatus.UNAVAILABLE;
	}

	void _onInit(String devId, ConnectionInfo info) async {
		var dev = _dev(devId, "?", !info.isIncomingConnection);
		await _bt?.acceptConnection(
			devId,
			onPayLoadRecieved: (devId, data) {
				print("rcv $devId ${data.type} ${data.bytes?.length}");
				if (data.bytes != null) {
					dev._rcv(data.bytes!);
				}
			}
		);
	}

	void _onRes(String devId, Status state) {
		print("res $devId $state");
		var dev = _devs[devId]!;
		switch (state) {
			case Status.CONNECTED:
				dev.status.value = DevStatus.CONNECTED;
			case Status.ERROR:
			case Status.REJECTED:
				dev.status.value = DevStatus.AVAILABLE;
		}
	}

	void _onDisconnect(String devId) {
		print("disc $devId");
		_devs[devId]!.status.value = DevStatus.AVAILABLE;
	}

	Device _dev(String devId, String name, [bool? outgoing]) {
		var dev = _devs.putIfAbsent(
			devId,
			() {
				var dev = Device._(this, devId, name, outgoing ?? true);
				devices = [..._devs.values, dev];
				notifyListeners();
				return dev;
			}
		);
      if (outgoing != null) {
         dev._outGoing = outgoing;
      }
      return dev;
   }

}
