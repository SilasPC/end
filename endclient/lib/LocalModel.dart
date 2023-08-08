
import 'package:common/AbstractEventModel.dart';
import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

const bool clientModelOnly = false;

class LocalModel
	extends AbstractEventModelWithRemoteSync<Model>
	with ChangeNotifier
{

	String _socketAddress = "http://localhost:3000";

	String get socketAddress => _socketAddress;
	set socketAddress(val) {
		if (val == _socketAddress) return;
		_socketAddress = val;
		_initSocket();
	}

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
		
		List<EnduranceEvent> evs = [];
		LocalModel model = LocalModel._(Model(), evs);
		model._initSocket();
		
		_instance = model;
		return model;
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
			connection.value = true;
			syncRemote();
		});
		socket.onDisconnect((_) {
			connection.value = false;
		});

		socket.on("push", (json) {
			// print("push $json");
			acceptPush(SyncPush.fromJson(json));
		});
		
	}

	io.Socket? _socket;

	LocalModel._(super.model, super.events);

	@override
	Future<SyncResult<Model>> $doRemoteSync(SyncRequest req) {
		Completer<SyncResult<Model>> c = Completer();
		_socket!.emitWithAck("sync", req.toJsonString(), ack: (json) {
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
