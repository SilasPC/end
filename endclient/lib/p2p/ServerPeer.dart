
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:common/p2p/Manager.dart';

class ServerPeer extends Peer {

	ServerPeer(this.uri) {
		_initSocket();
	}
	
	final String uri;
	late io.Socket _socket;

	void _initSocket() {

		_socket = io.io(
			uri,
			io.OptionBuilder()
				.setTransports(["websocket", "polling"])
				// .disableAutoConnect()
				.build()
		);

		_socket.onConnect((_) {
			print("server connect");
			setConnected(true);
		});
		_socket.onDisconnect((_) {
			print("server disconnect");
			setConnected(false);
		});

		for (var ev in SyncProtocol.events) {
			_socket.on(ev, (data) => _handler(ev, data as List));
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
