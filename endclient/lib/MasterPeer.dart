
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:common/p2p/Manager.dart';

class SocketPeer extends Peer {

	SocketPeer(String uri) {
		_initSocket(uri);
	}
	
	late io.Socket _socket;

	void _initSocket(String uri) {

		_socket = io.io(
			uri,
			io.OptionBuilder()
				.setTransports(["websocket", "polling"])
				.disableAutoConnect()
				.build()
		);

		_socket.onConnect((_) {
			connectStatus.add(true);
		});
		_socket.onDisconnect((_) {
			connectStatus.add(false);
		});

		// TODO: on any?
		_socket.on("presync", (data) => _handler("presync", data as List));
		_socket.on("sync", (data) => _handler("sync", data as List));
		
	}

	void _handler(String msg, List data) async {
		var bin = data.first as List<int>;
		var ack = data.last;
		var res = await onRecieve(msg, bin);
		if (res != null) {
			ack(res);
		}
	}
	
	@override
	bool isOutgoing() => true;

	@override
	void connect() => _socket.connect();

	@override
	void disconnect() => _socket.disconnect();


	@override
	Future<List<int>?> send(String msg, List<int> data) async {
		if (_socket.disconnected) {
			return null;
		}

		Completer<List<int>?> c = Completer();

		_socket.emitWithAck(
			msg,
			data,
			binary: true,
			ack: (msg) {
				if (!c.isCompleted) {
					c.complete(msg as List<int>);
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
