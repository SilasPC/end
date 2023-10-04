
import 'dart:io';
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/util.dart';
import 'package:esys_client/MasterPeer.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class ModelProvider extends StatelessWidget {
	const ModelProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<Settings, LocalModel>(
			lazy: false,
			create: (_) => PeerManagedModel(),
			// TODO: update socket address
			update: (_, set, mod) {
				// mod!.socket.socketAddress = set.serverURI;
				return mod!;
			},
			child: child,
		);
}

abstract class LocalModel with ChangeNotifier {

	ValueNotifier<bool> get connection;

	Model get model;
	Set<Event<Model>> get deletes;
	ReadOnlyOrderedSet<Event<Model>> get events;

	int get desyncCount;

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []]);
	Future<void> resetSync();

}

class PeerManagedModel with ChangeNotifier implements LocalModel {

	late PeerManager<Model> manager;
	final ValueNotifier<bool> _connection = ValueNotifier(false);
	Peer? _master;
	StreamSubscription? _masterConnectSub;

	PeerManagedModel() {
		manager = PeerManager(
			Platform.localHostname,
			SqfliteDatabase.create,
			Model.fromJson,
			EnduranceEvent.fromJson,
			Model.new,
		);
		_initMaster();
	}

	void _initMaster() {
		_master = SocketPeer(
			"http://localhost:3000" // TODO: what to do ?
		);
		_masterConnectSub?.cancel();
		_masterConnectSub = _master!.connectStatus
			.listen((value) => _connection.value = value);
		manager.setMaster(_master!);
	}

	@override
	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []])
		=> manager.add(evs, dels);

	@override
	ValueNotifier<bool> get connection => _connection;

	@override
	Set<Event<Model>> get deletes => manager.deletes;

	@override
	int get desyncCount => _master?.desyncCount ?? 0;

	@override
	ReadOnlyOrderedSet<Event<Model>> get events => manager.events;

	@override
	Model get model => manager.model;

	@override
	Future<void> resetSync() => manager.resetModel();

}

class SqfliteDatabase extends EventDatabase<Model> {

	final Database _db;
	SyncInfo _lastSaved = SyncInfo.zero();

	SyncInfo get lastSaved => _lastSaved;
	
	SqfliteDatabase._(this._db);
	static Future<SqfliteDatabase> create() async {
		var db = await _createDB();
		return SqfliteDatabase._(db);
	}

	@override
	Future<void> add(SyncMsg<Model> sr) async {
		var b = _db.batch();
		for (var ev in sr.evs) {
			b.insert("events", {
				"time": ev.time,
				"json": ev.toJsonString()
			});
		}
		for (var ev in sr.dels) {
			b.insert("deletes", {
				"time": ev.time,
				"json": ev.toJsonString()
			});
		}
		await b.commit(noResult: true);
	}

	@override
	Future<void> loadPeer(String peerId) async {
		var peer = await _db.query("peers", where: "peerId = ?", whereArgs: [peerId]);
		//if (peer.isEmpty) return null;
		// TODO: change interface
		// return null;
	}

	@override
	Future<void> clear({required bool keepPeers}) async {
		var b = _db.batch()
			..delete("events")
			..delete("deletes");
		if (!keepPeers) {
			b.delete("peers");
		}
		await b.commit(noResult: true);
		_lastSaved = SyncInfo.zero();
	}

	@override
	Future<Tuple<SyncMsg<Model>, PreSyncMsg?>> loadData() async {
		var data = await (
			_db.batch()
				..query("events", columns: ["json"])
				..query("deletes", columns: ["json"])
		).commit();
		var evs = (data[0]! as List)
			.map((d) => EnduranceEvent.fromJson(jsonDecode(d["json"] as String)))
			.toList();
		var dels = (data[1]! as List)
			.map((d) => EnduranceEvent.fromJson(jsonDecode(d["json"] as String)))
			.toList();
		// TODO: presyncmsg
		return Tuple(SyncMsg(evs, dels), null);
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
					..execute("""
						CREATE TABLE IF NOT EXISTS peers (
							peerId STRING NOT NULL PRIMARY KEY,
							sessionId INT NOT NULL,
							resetCount INT NOT NULL,
							lastSync STRING NOT NULL
						)
					"""))
					.commit(noResult: true);
			},
			version: 7
		);
		return db;
	}

}
