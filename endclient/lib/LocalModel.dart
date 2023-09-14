
import 'package:common/EventModel.dart';
import 'package:common/models/demo.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ModelProvider extends StatefulWidget {
	const ModelProvider({super.key, required this.child});

	final Widget child;

	@override
	ModelProviderState createState() => ModelProviderState();
}

class ModelProviderState extends State<ModelProvider> {

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<Settings, LocalModel>(
			lazy: false,
			create: (_) => LocalModel.create(),
			update: (_, set, mod) {
				mod!.connection.socketAddress = set.serverURI;
				return mod;
			},
			child: widget.child,
		);
}

class LocalModel extends SyncedEventModel<Model> with ChangeNotifier {

	late final SocketServer connection;

	factory LocalModel.create() {
		return LocalModel._(SocketServer(), Handle());
	}

	LocalModel.__(Handle handle, Future<SyncResult<Model>> Function(SyncRequest<Model>) syncFunc): super(handle, syncFunc);
	factory LocalModel._(SocketServer conn, Handle handle) {

		var h = Handle();
		var lm = LocalModel.__(h, conn.sendSync);
		lm.connection = conn;
      conn.onConnect = () => lm.sync();
      conn.onPush = (push) => lm.add(push.events, push.deletes);
		conn.onReset = () => lm.resetSync();

		return lm;
	}

}

class Handle extends EventModelHandle<Model> {

	Handle();

	@override
	Model createModel() => Model();
	@override
	Model revive(JSON json) => Model.fromJson(json);
	@override
	void didUpdate() {
		(model as LocalModel).notifyListeners();
	}
}


class SocketServer {

	final ValueNotifier<bool> status = ValueNotifier(false);

	String _socketAddress = "http://192.168.8.101:3000";

	String get socketAddress => _socketAddress;
	set socketAddress(String value) {
		if (value == _socketAddress) return;
		_socketAddress = value;
		_initSocket();
	}

	io.Socket? _socket;

	VoidCallback? onConnect, onDisconnect, onReset;
	void Function(SyncPush<Model> push)? onPush;

	Future<SyncResult<Model>> sendSync(SyncRequest<Model> req) {
		Completer<SyncResult<Model>> c = Completer();
		_socket!.emitWithAck("sync", req.toJsonString(), ack: (json) {
			c.complete(SyncResult.fromJSON(jsonDecode(json)));
		});
		return c.future;
	}

	void sendReset() {
		if (!_socket!.connected) return;
		_socket!.emit("reset");
	}

	SocketServer({this.onConnect, this.onDisconnect, this.onPush}) {
		_initSocket();
	}

	void _initSocket() {

		_socket?.close();
		status.value = false;
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
