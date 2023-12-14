
import 'dart:async';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/p2p/protocol.dart';
import 'package:common/util.dart';
import 'package:socket_io/socket_io.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {

	sqfliteFfiInit();
	databaseFactory = databaseFactoryFfi;

	var man = PeerManager<Model>(
		PrivatePeerIdentity.server("eSys"),
		() => NullDatabase("server", 0),//SqliteDatabase.create,
      MetaModel(),
	);

	Server io = Server();
	io.on("connection", (client_) {
		var client = client_ as Socket;
		print("connect");
		var peer = SocketPeer(client);
		man.addPeer(peer);

		setBinAck(client, "yield", (_) async {
			var ok = await man.yieldTo(peer);
			return ok ? SyncProtocol.OK : SyncProtocol.NOT_OK;
		});

	});
	io.listen(3000);
}

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

void setJsonAck2<T extends IJSON>(dynamic client, String msg, Reviver<T> reviver, FutureOr<T?>? Function(T) handler) {
	client.on(msg, (data) async {
		List dataList = data as List;
		var reqData = dataList.first;
		var ack = dataList.last;
		var res = await handler(reviver(IJSON.fromBin(reqData)));
		if (res != null) {
			ack(res.toJsonBin());
		}
	});
}

void setJsonAck<T extends IJSON>(dynamic client, String msg, Reviver<T> reviver, FutureOr<String?>? Function(T) handler) {
	client.on(msg, (data) async {
		List dataList = data as List;
		var reqData = dataList.first;
		var ack = dataList.last;
		var res = await handler(reviver(IJSON.fromBin(reqData)));
		if (res != null) {
			ack(res);
		}
	});
}

void setStringAck(dynamic client, String msg, FutureOr<String?>? Function(String) handler) {
	client.on(msg, (data) async {
		List dataList = data as List;
		var reqData = dataList.first;
		var ack = dataList.last;
		var res = await handler(reqData);
		if (res != null) {
			ack(res);
		}
	});
}

void setBinAck<T extends IJSON>(dynamic client, String msg, FutureOr<List<int>?>? Function(List<int>) handler) {
	client.on(msg, (data) async {
		List dataList = data as List;
		var reqData = (dataList.first as List).cast<int>();
		var ack = (dataList.last) as void Function(dynamic);
		var res = await handler(reqData);
		if (res != null) {
			ack(res);
		}
	});
}
