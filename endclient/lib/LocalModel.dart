
import 'package:common/EventModel.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

class LocalModel extends SyncedEventModel<Model> with ChangeNotifier {

   String _author = "default";
   String get author => _author;
   set author(val) {
      _author = val;
      SharedPreferences.getInstance()
         .then((sp) {
            sp.setString("author", _author);
         });
   }

	late final Connection connection;

	static LocalModel? _instance;
	static LocalModel get instance {
		if (_instance != null) {
			return _instance!;
		}
		
		LocalModel model = LocalModel._(Connection(), Handle());
		
		_instance = model;
		return model;
	}

	LocalModel._(Connection conn, Handle handle): super(handle, (SyncRequest<Model> req) {
		Completer<SyncResult<Model>> c = Completer();
		conn._socket!.emitWithAck("sync", req.toJsonString(), ack: (json) {
			c.complete(SyncResult.fromJSON(jsonDecode(json)));
		});
		return c.future;
	}) { handle.m = this; connection = conn; conn.lm = this; }

}

class Handle extends EventModelHandle<Model> {

	late LocalModel m;

	Handle();

	@override
	Model createModel() => Model();
	@override
	Model revive(JSON json) => Model.fromJson(json);
	@override
	void didUpdate() {
		m.notifyListeners();
	}
}

class Connection with ChangeNotifier {
	
	final ValueNotifier status = ValueNotifier(false);

	String _socketAddress = "http://192.168.8.101:3000";

	String get socketAddress => _socketAddress;
	set socketAddress(val) {
		if (val == _socketAddress) return;
		_socketAddress = val;
		_initSocket();
	}

	io.Socket? _socket;
	late LocalModel lm;

	Connection() {
		_initSocket();
	}

	void _initSocket() {
		_socket?.close();
		io.Socket socket = _socket = io.io(
			_socketAddress,
			io.OptionBuilder()
				.setTransports(["websocket"])
				.build()
		);
		/* socket.onConnectError((data) => print(data));
		socket.onConnectTimeout((data) => print(data));
		socket.onConnecting((data) => print(data)); */

		socket.onConnect((_) {
			status.value = true;
			lm.sync();
		});
		socket.onDisconnect((_) {
			status.value = false;
		});

		socket.on("push", (json) {
			// print("push $json");
			var push = SyncPush<Model>.fromJson(json);
			lm.add(push.events, push.deletes);
		});
		
	}

}
