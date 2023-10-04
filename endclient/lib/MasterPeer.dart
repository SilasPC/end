
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:common/p2p/Manager.dart';

class SocketPeer extends Peer {
	
	final ValueNotifier<bool> status = ValueNotifier(false);

	String? _socketAddress;

	String? get socketAddress => _socketAddress;
	set socketAddress(String? value) {
		if (value == _socketAddress || value == null) return;
		_socketAddress = value;
		_initSocket();
	}

	io.Socket? _socket;

	int _initCount = 0;
	void _initSocket() {

		var initCount = ++_initCount;

		_socket?.disconnect();
		status.value = false;
		onDisconnect?.call();
		// CHECK: io.io will not reconnect to a previously connected socket ???
		io.Socket socket = _socket = io.io(
			_socketAddress!,
			io.OptionBuilder()
				.setTransports(["websocket"]) // TODO: add "polling"
				.build()
		);

		socket.onConnect((_) {
			if (initCount != _initCount) return;
			print("connect $initCount");
			status.value = true;
			onConnect?.call();
		});
		socket.onDisconnect((_) {
			if (initCount != _initCount) return;
			print("disconnect $initCount");
			status.value = false;
			onDisconnect?.call();
		});

		socket.on("reset", (_) {
			onReset?.call();
		});
		
	}

	@override
	Future<Msg?> sendSync(Msg msg) async {

		if (_socket!.disconnected) {
			return null;
		}

		Completer<Msg?> c = Completer();

		_socket!.emitWithAck("sync", msg.toJsonBin(), binary: true, ack: (bin) {
			if (!c.isCompleted) {
				c.complete(Msg.fromBin(bin));
			}
		});
		Timer(const Duration(seconds: 5), () {
			if (!c.isCompleted) {
				c.complete();
			}
		});
		return c.future;
	}

}
