import 'dart:convert';
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/db.dart';
import 'package:common/p2p/keys.dart';
import 'package:common/p2p/protocol.dart';
import 'package:common/util.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SqliteDatabase extends EventDatabase<EnduranceModel> {
  final Database _db;
  SyncInfo _lastSaved = SyncInfo.zero();

  SyncInfo get lastSaved => _lastSaved;

  SqliteDatabase._(this._db);
  static Future<SqliteDatabase> create() async {
    var db = await _createDB();
    return SqliteDatabase._(db);
  }

  @override
  Future<void> add(SyncMsg<EnduranceModel> sr) async {
    var b = _db.batch();
    for (int i = 0; i < sr.evs.length; i++) {
      var ev = sr.evs[i];
      b.insert("events", {
        "time": ev.time,
        "json": ev.toJsonString(),
        "sign": jsonEncode(SignatureConverter().toJson(sr.sigs[i])),
      });
    }
    for (var ev in sr.dels) {
      b.insert("deletes", {"time": ev.time, "json": ev.toJsonString()});
    }
    await b.commit(noResult: true);
  }

  @override
  Future<(PreSyncMsg, SyncInfo)?> loadPeer(String peerId) async {
    var peer = await _db.query("peers", where: "id = ?", whereArgs: [peerId]);
    if (peer.isEmpty) return null;
    var psm = PreSyncMsg.fromJson(jsonDecode(peer.first["preSync"] as String));
    var si = SyncInfo.fromJson(jsonDecode(peer.first["syncInfo"] as String));
    return (psm, si);
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
  Future<(SyncMsg<EnduranceModel>, PreSyncMsg?)> loadData() async {
    var data = await (_db.batch()
          ..query("events")
          ..query("deletes")
          ..query("peers")
          ..query("self"))
        .commit();

    var [events, deletes, peers, self] = data.cast<List>();

    var evs = events
        .map((d) => EnduranceEvent.fromJson(jsonDecode(d["json"] as String)))
        .toList();
    var sigs = events
        .map((d) =>
            SignatureConverter().fromJson(jsonDecode(d["sign"] as String)))
        .toList();
    var dels = deletes
        .map((d) => EnduranceEvent.fromJson(jsonDecode(d["json"] as String)))
        .toList();
    var preSyncs = peers
        .map((d) => PreSyncMsg.fromJson(jsonDecode(d["preSync"])))
        .toList();
    var selfPS = maybe<JSON, PreSyncMsg>(
        self.firstOrNull, (d) => PreSyncMsg.fromJson(jsonDecode(d["preSync"])));
    var identities =
        preSyncs.map((d) => d.identity).whereType<PeerIdentity>().toList();

    return (SyncMsg(evs, dels, sigs, identities), selfPS);
  }

  static Future<Database> _createDB() async {
    var path = join(await getDatabasesPath(), "events.db");
    var db = await openDatabase(path,
        onCreate: (db, _) => _resetDatabase(db),
        onUpgrade: (db, _, __) => _resetDatabase(db),
        onDowngrade: (db, _, __) => _resetDatabase(db),
        version: 17);
    return db;
  }

  static Future<void> _resetDatabase(Database db) async {
    await (db.batch()
          ..execute("DROP TABLE IF EXISTS deletes")
          ..execute("DROP TABLE IF EXISTS events")
          ..execute("DROP TABLE IF EXISTS peers")
          ..execute("""CREATE TABLE IF NOT EXISTS deletes (
				time INT NOT NULL,
				json STRING NOT NULL
			)""")
          ..execute("""
				CREATE TABLE IF NOT EXISTS events (
					time INT NOT NULL,
					json STRING NOT NULL,
					sign STRING NOT NULL
				)""")
          ..execute("""
				CREATE TABLE IF NOT EXISTS peers (
					id STRING NOT NULL PRIMARY KEY,
					preSync STRING NOT NULL,
					syncInfo STRING NOT NULL
				)
			""")
          ..execute("""
				CREATE TABLE IF NOT EXISTS self (
					preSync STRING NOT NULL
				)
			""")
          ..insert("self", {"preSync": PreSyncMsg(null, 0, 0).toJsonString()}))
        .commit(noResult: true);
  }

  @override
  Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo) async {
    var id = state.identity?.name;
    if (id == null) return;
    var row = {
      "id": id,
      "preSync": state.toJsonString(),
      "syncInfo": syncInfo.toJsonString(),
    };
    await _db.insert("peers", row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> saveData(PreSyncMsg state) async {
    var row = {
      "preSync": state.toJsonString(),
    };
    await _db.update("peers", row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
