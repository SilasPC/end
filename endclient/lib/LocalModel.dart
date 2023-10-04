
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

	int get desyncCount =>
		events.length + deletes.length
		- _model.lastSyncLocal.evLen - _model.lastSyncLocal.delLen;
	
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
      connection.onConnect = () => _mutex.protect(() async {
         try {
			   await _model.sync();
         } catch (_) {}
		});
      connection.onPush = (push) => _mutex.protect(() async {
			_model.add(push.events, push.deletes);
			await _save();
		});
		connection.onReset = () => _mutex.protect(() async {
			_model.reset();
			await _save();
		});
	}

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []]) async {
		_mutex.protect(() async {
			if (connection.status.value) {
            try {
				   await _model.addSync(evs, dels);
            } catch (_) {}
			} else {
				_model.add(evs, dels);
			}
			await _save();
		});
	}

	Future<void> manualSync() async {
		_mutex.protect(() async {
         try {
			   await _model.sync();
         } catch (_) {}
			await _save();
		});
	}

	Future<void> resetSync() async {
		_mutex.protect(() async {
			_db.clear();
			_model.reset();
         try {
            if (connection.status.value) {
               await _model.sync();
            }
         } catch (_) {}
			await _save();
		});
	}

	Future<void> reset() async {
		_mutex.protect(() async {
			await _db.clear();
			_model.reset();
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
	EnduranceEvent reviveEvent(JSON json) => EnduranceEvent.fromJson(json);
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
		if (_socket!.disconnected) {
			throw StateError("attempt to sync with unconnected server");
		}
		Completer<SyncResult<Model>> c = Completer();

		_socket!.emitWithAck("sync", req.toJsonBin(), binary: true, ack: (json) {
			if (!c.isCompleted) {
				c.complete(SyncResult.fromJSON(jsonDecode(utf8.decode(json))));
			}
		});
		Timer(const Duration(seconds: 5), () {
			if (!c.isCompleted) {
				c.completeError(TimeoutException("server sync timed out"));
			}
		});
		return c.future;
	}

	void sendReset() {
		if (!_socket!.connected) return;
		_socket!.emit("reset");
	}

	SocketServer({this.onConnect, this.onDisconnect, this.onPush});

	int _initCount = 0;
	void _initSocket() {

		var initCount = ++_initCount;

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

      // FEAT: sync should just be symmetric (p2p)
		socket.on("push", (json) {
			var push = SyncPush<Model>.fromJson(json);
			onPush?.call(push);
		});

		socket.on("reset", (_) {
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
		for (var ev in sr.events) {
			b.insert("events", {
				"time": ev.time,
				"json": ev.toJsonString()
			});
		}
		for (var ev in sr.deletes) {
			b.insert("deletes", {
				"time": ev.time,
				"json": ev.toJsonString()
			});
		}
		b.update("syncinfo", sr.syncInfo.toJson());
		await b.commit(noResult: true);
	}

	Future<void> clear() async {
		_db.batch()
			..delete("events")
			..delete("deletes")
			..update("syncinfo", SyncInfo.zero().toJson())
			..commit(noResult: true);
		_lastSaved = SyncInfo.zero();
	}

	Future<SyncResult<Model>> loadAll() async {
		var b = _db.batch();
		b.query("events", columns: ["json"]);
		b.query("deletes", columns: ["json"]);
		b.query("syncinfo");
		var data = await b.commit();
		var evs = (data[0]! as List)
			.map((d) => eventFromJSON(jsonDecode(d["json"] as String)))
			.toList();
		var dels = (data[1]! as List)
			.map((d) => eventFromJSON(jsonDecode(d["json"] as String)))
			.toList(); 
		var si = SyncInfo.fromJson((data[2]! as List).first as JSON);
		return SyncResult(evs, dels, si);
	}

	static Future<Database> _createDB() async {
		WidgetsFlutterBinding.ensureInitialized();
		var path = join(await getDatabasesPath(), "events.db");
		var db = await openDatabase(
			path,
			onUpgrade: (db, v0, v1) async {
				await (db.batch()
					..execute("CREATE TABLE IF NOT EXISTS deletes (time INT NOT NULL, json STRING NOT NULL)")
					..execute("CREATE TABLE IF NOT EXISTS events (time INT NOT NULL, json STRING NOT NULL)")
					..execute("CREATE TABLE IF NOT EXISTS syncinfo (evLen INT NOT NULL, delLen INT NOT NULL)")
					..insert("syncinfo", SyncInfo.zero().toJson()))
					.commit(noResult: true);
			},
			version: 6
		);
		return db;
	}

}
