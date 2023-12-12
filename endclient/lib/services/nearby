
import 'dart:async';
import 'dart:io';

import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/msg_encoder.dart' as coding;
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

// IGNORED: CHECK: race conditions
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
	
	Device._(this._man, this.devId, this.name, this._outGoing) {
		status.addListener(() {
			setConnected(status.value == DevStatus.CONNECTED);
		});
	}

   @override
	void connect() async {
		if (unavailable) return;
		if (connected) return;
		try {
			await _man._bt?.requestConnection(
				_man.localName,
				devId,
				onConnectionInitiated: _man._onInit,
				onConnectionResult: _man._onRes, 
				onDisconnected: _man._onDisconnect, 
			);
		}
		catch (e) {
			print(e);
		}
	}

   @override
	void disconnect() async {
		if (disconnected) return;
		try {
			await _man._bt?.disconnectFromEndpoint(devId);
		}
		finally {
			if (available) {
				status.value = DevStatus.AVAILABLE;
			}
			setConnected(false);
		}
	}

   int _seqNr = 0;
   final Map<int, Completer<List<int>?>> _completers = {};

   @override
	Future<List<int>?> send(String msg, List<int> data) async {
		if (disconnected) return null;

      final c = Completer<List<int>?>();

		final seqNr = _seqNr++;
      _completers[seqNr] = c;
		await _man._bt?.sendBytesPayload(devId, coding.encodeMsg(seqNr, msg, data));

      Timer(const Duration(seconds: 5), () {
         if (!c.isCompleted) {
            c.complete(null);
         }
         _completers.remove(seqNr);
      });

		return c.future;
	}

   void _rcv(List<int> data) async {

		final (
			seqNr,
			msg,
			msgData,
			isReply
		) = coding.decodeMsg(data);

      if (isReply) {
         var c = _completers.remove(seqNr);
         if (c case Completer c when !c.isCompleted) {
            c.complete(data.sublist(5));
         }
      } else {
         var reply = await onRecieve(msg, msgData);
         if (reply == null) return;
		   _man._bt?.sendBytesPayload(
				devId, 
				coding.encodeReply(seqNr, reply)
			);
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
				await _getPerms();
				await _startAdvertising();
				await _startDiscovery();
			} else {
				await _kill();
			}
			_enabled = enable;
		});
	}

	bool _autoConnect = false;
	bool get autoConnect => _autoConnect;
	set autoConnect (bool val) {
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
			return _kill();
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
		).catchError((e) {print(e);return false;}) ?? false;

	Future<bool> _startDiscovery() async =>
		await _bt?.startDiscovery(
			localName,
			Strategy.P2P_CLUSTER,
			onEndpointFound: _onFound,
			onEndpointLost: _onLost,
			serviceId: SERVICE_ID,
		).catchError((e) {print(e);return false;}) ?? false;

	Future<void> _kill() async {
		await _bt?.stopDiscovery();
		await _bt?.stopAdvertising();
		await _bt?.stopAllEndpoints();
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
		// print("found $devId $name $sid");
		var dev = _dev(devId, name);
		if (dev.disconnected) {
			dev.status.value = DevStatus.AVAILABLE;
		}
		if (_autoConnect) {
			dev.connect();
		}
	}
	
	void _onLost(String? devId) {
		// print("lost $devId");
		_devs[devId]?.status.value = DevStatus.UNAVAILABLE;
	}

	void _onInit(String devId, ConnectionInfo info) async {
		var dev = _dev(devId, "?", !info.isIncomingConnection);
		await _bt?.acceptConnection(
			devId,
			onPayLoadRecieved: (devId, data) {
				if (data.bytes case Uint8List bytes) {
					dev._rcv(bytes);
				}
			}
		);
	}

	void _onRes(String devId, Status state) {
		// print("res $devId $state");
		var dev = _devs[devId];
		if (dev == null) return;
		switch (state) {
			case Status.CONNECTED:
				dev.status.value = DevStatus.CONNECTED;
				dev.setConnected(true);
			case Status.ERROR:
			case Status.REJECTED:
				dev.status.value = DevStatus.AVAILABLE;
		}
	}

	void _onDisconnect(String devId) {
		// print("disc $devId");
		_devs[devId]?.status.value = DevStatus.AVAILABLE;
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
