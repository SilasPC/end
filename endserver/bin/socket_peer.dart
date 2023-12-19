
import 'dart:async';

import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/protocol.dart';
import 'package:socket_io/socket_io.dart';

class SocketPeer extends Peer {

	final Socket socket;

	SocketPeer(this.socket) {
		socket.on("connect", (_) {
			print("connect $id");
			setConnected(true);
		});
		socket.on("disconnect", (_) {
			print("disconnect $id");
			setConnected(false);
		});
		for (var ev in SyncProtocol.events) {
			socket.on(ev, (data) => _handler(ev, data));
		}
	}

	void _handler(String msg, List data) async {
		var bin = (data.first as List).cast<int>();
		var ack = data.last;
		var res = await onRecieve(msg, bin);
		if (res != null) {
			ack(res);
		}
	}

	@override
	bool isOutgoing() => false;

	@override
	void connect() {}

	@override
	void disconnect() => socket.disconnect();

	@override
	Future<List<int>?> send(String msg, List<int> data) async {
		if (socket.disconnected) {
			return null;
		}

		Completer<List<int>?> c = Completer();

		socket.emitWithAck(
			msg,
			data,
			binary: true,
			ack: (msg) {
				if (!c.isCompleted) {
					c.complete((msg as List).cast<int>());
				}
			}
		);
		Timer(const Duration(seconds: 5), () {
			if (!c.isCompleted) {
				c.complete(null);
			}
		});
		return c.future;
	}

}