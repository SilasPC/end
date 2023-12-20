import 'dart:async';
import 'dart:io';
import 'package:common/p2p/Manager.dart';
import 'package:flutter/foundation.dart';

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
  void connect() {}

  @override
  void disconnect() {}

  @override
  Future<List<int>?> send(String msg, List<int> data) async => null;
}

class NearbyManager with ChangeNotifier {
  static const String SERVICE_ID = "com.example.endclient";
  final String localName = Platform.localHostname;
  List<Device> devices = [];
  final bool available = Platform.isAndroid | Platform.isIOS;
  bool enabled = false, autoConnect = false;
}
