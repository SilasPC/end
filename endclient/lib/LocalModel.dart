
import 'package:common/EventModel.dart';
import 'package:common/models/demo.dart';
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

	static LocalModel? _instance;
	static LocalModel get instance {
		if (_instance != null) {
			return _instance!;
		}

		var conn = SocketServer(
			onPush: (push) {
				_instance!.add(push.events, push.deletes);
			}
		);
		
		_instance = LocalModel._(conn, Handle());
		return _instance!;
	}

	late final ServerConnection connection;

	LocalModel.__(Handle handle, Future<SyncResult<Model>> Function(SyncRequest<Model>) syncFunc): super(handle, syncFunc);
	factory LocalModel._(ServerConnection conn, Handle handle) {

		var h = Handle();
		var lm = LocalModel.__(h, conn.sendSync);
		h.m = lm;
		lm.connection = conn;

		return lm;
	}

}

class Handle extends EventModelHandle<Model> {

	LocalModel? m;

	Handle();

	@override
	Model createModel() => Model();
	@override
	Model revive(JSON json) => Model.fromJson(json);
	@override
	void didUpdate() {
		m?.notifyListeners();
	}
}

abstract class ServerConnection {
	ServerConnection({
		VoidCallback? onConnect, onDisconnect,
		void Function(SyncPush<Model>)? onPush,
	});
	final ValueNotifier<bool> status = ValueNotifier(false);
	Future<SyncResult<Model>> sendSync(SyncRequest<Model> req);
}

class MockServer extends ServerConnection {

	late final EventModel<Model> model;

	MockServer() {
		model = EventModel(Handle());
		model.add(demoInitEvent(nowUNIX() + 300));
		status.value = true;
	}

	@override
	Future<SyncResult<Model>> sendSync(SyncRequest<Model> req)
		=> Future.value(req.applyTo(model));

}

class SocketServer extends ServerConnection {

	final String _socketAddress = "http://192.168.8.101:3000";

	io.Socket? _socket;

	VoidCallback? onConnect, onDisconnect;
	void Function(SyncPush<Model> push)? onPush;

	@override
	Future<SyncResult<Model>> sendSync(SyncRequest<Model> req) {
		Completer<SyncResult<Model>> c = Completer();
		_socket!.emitWithAck("sync", req.toJsonString(), ack: (json) {
			c.complete(SyncResult.fromJSON(jsonDecode(json)));
		});
		return c.future;
	}

	SocketServer({this.onConnect, this.onDisconnect, this.onPush}) {
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

		socket.onConnect((_) {
			status.value = true;
			onConnect?.call();
		});
		socket.onDisconnect((_) {
			status.value = false;
			onDisconnect?.call();
		});

		socket.on("push", (json) {
			var push = SyncPush<Model>.fromJson(json);
			onPush?.call(push);
		});
		
	}
}
