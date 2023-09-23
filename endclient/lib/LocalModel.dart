
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:sqflite/sqflite.dart';

class ModelProvider extends StatelessWidget {
	const ModelProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<Settings, LocalModel>(
			lazy: false,
			create: (_) => LocalModel(),
			update: (_, set, mod) {
				mod!.connection.socketAddress = set.serverURI;
				return mod;
			},
			child: child,
		);
}

class LocalModel with ChangeNotifier {

	final Mutex _mutex = Mutex();
	late SyncedEventModel<Model> _model;
	late final SocketServer connection = SocketServer();
	late final EventDatabase _db;

	Model get model => _model.model;
	Set<Event<Model>> get deletes => _model.deletes;
	ReadOnlyOrderedSet<Event<Model>> get events => _model.events;
	
	LocalModel() {	
		_initModel();
		_mutex.protect(() async {
			_db = await EventDatabase.create();
			var data = await _db.loadAll();
			_model.reset();
			_model.lastSyncLocal = _model.lastSyncRemote = data.syncInfo;
			_model.add(data.events, data.deletes);
		});
	}

	void _initModel() {
		var h = Handle(notifyListeners);
		_model = SyncedEventModel(h, connection.sendSync);
      /* connection.onConnect = () => _mutex.protect(() async {
			await _model.sync();
		}); */
      connection.onPush = (push) => _mutex.protect(() async {
			_model.add(push.events, push.deletes);
			await _save();
		});
		connection.onReset = () => _mutex.protect(() async {
			print("got reset");
			_model.reset();
			await _save();
		});
	}

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []]) async {
		print("addSync");
		_mutex.protect(() async {
			print("addSync entry");
			if (connection.status.value) {
				await _model.addSync(evs, dels);
			} else {
				_model.add(evs, dels);
			}
			await _save();
			print("addSync exit");
		});
	}

	Future<void> manualSync() async {
		print("manualSync");
		_mutex.protect(() async {
			print("manualSync entry");
			connection._socket!.emit("test");
			await _model.sync();
			await _save();
			print("manualSync exit");
		});
	}

	Future<void> resetSync() async {
		print("resetSync");
		_mutex.protect(() async {
			print("resetSync entry");
			_db.clear();
			_model.reset();
			if (connection.status.value) {
				await _model.sync();
			}
			await _save();
			print("resetSync exit");
		});
	}

	Future<void> reset() async {
		print("reset");
		_mutex.protect(() async {
			print("reset entry");
			await _db.clear();
			_model.reset();
			print("reset exit");
		});
	}

	Future<void> _save() async {
		await _db.add(_model.getNewerData(_db._lastSaved));
	}

}

class Handle extends EventModelHandle<Model> {

	final void Function() onUpdate;

	Handle(this.onUpdate);

	@override
	Model createModel() => Model();
	@override
	Model revive(JSON json) => Model.fromJson(json);
	@override
	void didUpdate() => onUpdate();
	@override
	void didReset() => onUpdate();
}


class SocketServer {

	final ValueNotifier<bool> status = ValueNotifier(false);

	String? _socketAddress;

	String? get socketAddress => _socketAddress;
	set socketAddress(String? value) {
		if (value == _socketAddress || value == null) return;
		_socketAddress = value;
		_initSocket();
	}

	io.Socket? _socket;

	VoidCallback? onConnect, onDisconnect, onReset;
	void Function(SyncPush<Model> push)? onPush;

	Future<SyncResult<Model>> sendSync(SyncRequest<Model> req) {
		print("syncfunc 1");
		if (_socket!.disconnected) {
			throw StateError("attempt to sync with unconnected server");
		}
		print("syncfunc 2");
		Completer<SyncResult<Model>> c = Completer();
		// FIXME: why does this disconnect and reconnnect when executed?
		_socket!.emitWithAck("sync", req.toJsonString(), ack: (json) {
			print("backsync");
			if (!c.isCompleted) {
				//print("syncfunc response completing");
				c.complete(SyncResult.fromJSON(jsonDecode(json)));
			}
		});
		Timer(const Duration(seconds: 5), () {
			if (!c.isCompleted) {
				print("sync timeout");
				c.completeError(TimeoutException("server sync timed out"));
			}
		});
		print("syncfunc 3");
		return c.future;
	}

	void sendReset() {
		if (!_socket!.connected) return;
		_socket!.emit("do-reset");
	}

	SocketServer({this.onConnect, this.onDisconnect, this.onPush});

	int _initCount = 0;
	void _initSocket() {

		var initCount = ++_initCount;

		print("init $initCount $_socketAddress");

		_socket?.disconnect();
		status.value = false;
		onDisconnect?.call();
		// FIXME: io.io will not reconnect to a previously connected socket ???
		io.Socket socket = _socket = io.io(
			_socketAddress!,
			io.OptionBuilder()
				.setTransports(["websocket"])
				.build()
		);

		socket.onConnect((_) {
			if (initCount != _initCount) return;
			print("connect $initCount");
			status.value = true;
			onConnect?.call();
		});
		socket.onDisconnect((_) {
			if (initCount != _initCount) return;
			print("disconnect $initCount");
			status.value = false;
			onDisconnect?.call();
		});

		socket.on("push", (json) {
			var push = SyncPush<Model>.fromJson(json);
			onPush?.call(push);
		});

		socket.on("do-reset", (_) {
			onReset?.call();
		});
		
	}
}

class EventDatabase {

	final Database _db;
	SyncInfo _lastSaved = SyncInfo.zero();
	
	EventDatabase._(this._db);
	static Future<EventDatabase> create() async {
		var db = await _createDB();
		return EventDatabase._(db);
	}

	Future<void> add(SyncResult<Model> sr) async {
		var b = _db.batch();
		// TODO: save deletes
		for (var ev in sr.events) {
			b.insert("events", {
				"time": ev.time,
				"json": ev.toJsonString()
			});
		}
		b.update("syncinfo", sr.syncInfo.toJson());
		await b.commit();
	}

	Future<void> clear() async {
		_db.batch()
			..delete("events")
			..update("syncinfo", SyncInfo.zero().toJson())
			..commit();
		_lastSaved = SyncInfo.zero();
	}

	Future<SyncResult<Model>> loadAll() async {
		var b = _db.batch();
		// TODO: deletes
		b.query("events", columns: ["json"]);
		b.query("syncinfo");
		var data = await b.commit();
		var evs = (data[0]! as List)
			.map((d) => eventFromJSON(jsonDecode(d["json"] as String)))
			.toList(); 
		var si = SyncInfo.fromJson((data[1]! as List).first as JSON);
		return SyncResult(evs, [], si);
	}

	static Future<Database> _createDB() async {
		WidgetsFlutterBinding.ensureInitialized();
		var path = join(await getDatabasesPath(), "events.db");
		print(path);
		var db = await openDatabase(
			path,
			onUpgrade: (db, v0, v1) async {
				await (db.batch()
					..execute("CREATE TABLE events (time INT NOT NULL, json STRING NOT NULL)")
					..execute("CREATE TABLE syncinfo (evLen INT NOT NULL, delLen INT NOT NULL)")
					..insert("syncinfo", SyncInfo.zero().toJson()))
					.commit();
			},
			version: 5
		);
		return db;
	}

}
