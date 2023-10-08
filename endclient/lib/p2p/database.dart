
import 'dart:convert';

import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/util.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
	Future<Tuple<PreSyncMsg, SyncInfo>?> loadPeer(String peerId) async {
		var peer = await _db.query("peers", where: "peerId = ?", whereArgs: [peerId]);
		if (peer.isEmpty) return null;
		var psm = PreSyncMsg.fromJson(peer.first);
		var si = SyncInfo.fromJson(peer.first);

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
		var path = join(await getDatabasesPath(), "events.db");
		var db = await openDatabase(
			path,
			onUpgrade: (db, v0, v1) async {
				await (db.batch()
					..execute("DROP TABLE IF EXISTS deletes")
					..execute("DROP TABLE IF EXISTS events")
					..execute("DROP TABLE IF EXISTS peers")

					..execute("CREATE TABLE IF NOT EXISTS deletes (time INT NOT NULL, json STRING NOT NULL)")
					..execute("CREATE TABLE IF NOT EXISTS events (time INT NOT NULL, json STRING NOT NULL)")
					..execute("""
						CREATE TABLE IF NOT EXISTS peers (
							peerId STRING NOT NULL PRIMARY KEY,
							sessionId INT NOT NULL,
							resetCount INT NOT NULL,
							evLen INT NOT NULL,
							delLen INT NOT NULL
						)
					"""))
					.commit(noResult: true);
			},
			version: 8
		);
		return db;
	}
	
	@override
	Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo) {
		var row = state.toJson()..addEntries(syncInfo.toJson().entries);
		return _db.update(
			"peers",
			row,
			where: "peerId = ?",
			whereArgs: [state.peerId]
		);
	}

}
