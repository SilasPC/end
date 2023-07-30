import 'package:common/AbstractEventModel.dart';
import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:common/Event.dart';
import 'package:common/model.dart';
import 'package:common/util.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

const String serverUri = "localhost:3000";
const bool clientModelOnly = false;

class LocalModel
	extends AbstractEventModelWithRemoteSync<Model>
	with ChangeNotifier
{

   String _author = "default";
   String get author => _author;
   set author(val) {
      _author = val;
      SharedPreferences.getInstance()
         .then((sp) {
            sp.setString("author", _author);
         });
   }
	final ValueNotifier connection = ValueNotifier(false);
	// ChangeNotifier get connection => _connection;

	static LocalModel? _instance;
	static LocalModel get instance {
		if (_instance != null) {
			return _instance!;
		}
		
		io.Socket socket = io.io(
			serverUri,
			io.OptionBuilder()
				.setTransports(["websocket"])
				//.disableAutoConnect()
				.build()
		);

		List<Event> evs = [];
		LocalModel model = LocalModel._(socket, Model(), evs);

		socket.onConnectError((data) => print(data));
		socket.onConnectTimeout((data) => print(data));
		socket.onConnecting((data) => print(data));

		socket.onDisconnect((_) {
			print("disconnected");
			model.connection.value = false;
		});

		socket.on("push", (json) {
			print("push $json");
			model.acceptPush(SyncPush.fromJSON(json));
		});

		socket.onConnect((_) {
			print("connected");
			model.connection.value = true;
			model.syncRemote();
		});
		
		/* if (!clientModelOnly)
			socket.connect(); */
		
		_instance = model;
		return model;
	}

	final io.Socket _socket;

	LocalModel._(this._socket, super.model, super.events);

	@override
	Future<SyncResult<Model>> $doRemoteSync(SyncRequest req) {
		Completer<SyncResult<Model>> c = Completer();
		_socket.emitWithAck("sync", req.toJsonString(), ack: (json) {
			c.complete(SyncResult.fromJSON(jsonDecode(json), Model.fromJson));
		});
		return c.future;
	}

	@override
	Model $reviveModel(JSON json) => Model.fromJson(json);

	@override
	void $onUpdate() {
		print("notify");
		notifyListeners();
	}

}
