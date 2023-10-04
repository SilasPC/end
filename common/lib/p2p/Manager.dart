
import 'dart:async';

import 'package:common/EventModel.dart';
import 'package:common/models/Model.dart';
import 'package:mutex/mutex.dart';

import '../util.dart';
import 'db.dart';

typedef Ev = Event<Model>;

class InitMsg {
	final int sessionId;
	InitMsg(this.sessionId);
}

class Msg extends IJSON {
	final List<Ev> evs, dels;
	Msg(this.evs, this.dels);

	factory Msg.fromBin(List<int> bin) => Msg.fromJson(IJSON.fromBin(bin));
	factory Msg.fromJson(JSON json) => unimpl();

}

abstract class Peer {

	Mutex _mutex = Mutex();
	SyncInfo _lastLocal = SyncInfo.zero();

	// Future<bool> connect();
	Future<Msg?> sendSync(Msg msg);

}

class P2PManager {

	VoidCallback? onUpdate;

	int _sessionId = 0;
	int get sessionId => _sessionId;
	late final EventDatabase _db;
	final Mutex _mutex = Mutex();
	List<Peer> _peers = [];
	final Peer? master;
	late EventModel<Model> _em;
	Stream<Peer> _peerSource;

	P2PManager(
		this.master,
		this._peerSource,
		AsyncProducer<EventDatabase> createDb
	) {
		_initModel();
		_initDatabase(createDb);
		_initPeerSource();
	}

	void _initModel() {
		var h = Handle(() {
			onUpdate?.call();
		});
		_em = EventModel(h);
	}

	void _initDatabase(AsyncProducer<EventDatabase> createDb) {
		_mutex.protect(() async {
			_db = await createDb();
			var data = await _db.loadAll();
			_em.reset();
			_em.add(data.evs, data.dels);
		});
	}

	void _initPeerSource() {
		_peerSource.listen((peer) {
			if (_peers.contains(peer)) return;
			_peers.add(peer);
		});
	}

	void add(List<Ev> evs, [List<Ev> dels = const []]) {
		_mutex.protect(() async {
			_em.add(evs, dels);
			await _save();
			_broadcastSync();
		});
	}
	
	/* Future<void> reset() async {
		_mutex.protect(() async {
			await _db.clear();
			_em.reset();
			// TODO: ensure other peers know this
		});
	} */

	Future<void> _save() async {
		var data = _em.getNewerData(_db.lastSaved());
		await _db.add(Msg(data.events, data.deletes), _em.syncState);
	}

	void _broadcastSync() async {
		for (var p in _peers) {
			p._mutex.protect(() async {
				var ss = _em.syncState;
				if (p._lastLocal == ss) return;
				var data = _em.getNewerData(p._lastLocal);
				var res = await p.sendSync(Msg(data.events, data.deletes));
				if (res == null) {
					// timeout
					return;
				}
				p._lastLocal = ss;
				if (res.evs.isNotEmpty || res.dels.isNotEmpty) {
					add(res.evs, res.dels);
					// TODO: ack to peer
				}
			});
		}
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

class LocalPeer extends Peer {

	P2PManager man;

	SyncInfo _lastRemote = SyncInfo.zero();

	LocalPeer(this.man);

	@override
	Future<Msg?> sendSync(Msg msg) async {
		man.add(msg.evs, msg.dels);
		var data = man._em.getNewerData(_lastRemote);
		_lastRemote = man._em.syncState; // TODO: should only happen after ack
		return Msg(data.events, data.deletes);
	}

}
