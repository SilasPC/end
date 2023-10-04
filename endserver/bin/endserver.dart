
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/util.dart';
import 'package:socket_io/socket_io.dart';

File backupFile = File("../backup.events.json");

Future<void> main() async {

	var man = PeerManager<Model>(
		"root-server",
		NullDatabase.new,
		Model.fromJson,
		EnduranceEvent.fromJson,
		Model.new,
	);

	Server io = Server();
	io.on("connection", (client_) {
		var client = client_ as Socket;
		print("connect");
		man.addPeer(SocketPeer(client));
	});
	io.listen(3000);
}

class Handle extends EventModelHandle<Model> {

	@override
	Model createModel() => Model();

	@override
	Model revive(JSON json) => Model.fromJson(json);

	@override
	EnduranceEvent reviveEvent(JSON json) => EnduranceEvent.fromJson(json);

	@override
	Future<void> didUpdate() async {
		// TODO: database or mutex/redundancy for error-correction
		await backupFile.writeAsString(
			jsonEncode(iterj(model.events.iteratorInsertion)),
			flush: true
		);
		print("saved");
	}

}

class SocketPeer extends Peer {

	final Socket socket;

	SocketPeer(this.socket) {
		socket.on("connect", (_) {
			connectStatus.add(true);
		});
		socket.on("disconnect", (_) {
			connectStatus.add(false);
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
