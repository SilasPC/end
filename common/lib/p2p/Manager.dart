
import 'dart:async';
import 'dart:math';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:mutex/mutex.dart';
import '../util.dart';
import 'db.dart';

class PreSyncMsg extends IJSON {

	final int protocolVersion;
	final String peerId;
	final int sessionId;
	final int resetCount;
	PreSyncMsg(this.peerId, this.sessionId, this.resetCount, {this.protocolVersion = SyncProtocol.VERSION});
	
	JSON toJson() => {
		"protocolVersion": protocolVersion,
		"peerId": peerId,
		"sessionId": sessionId,
		"resetCount": resetCount,
	};

	factory PreSyncMsg.fromBin(List<int> bin) => PreSyncMsg.fromJson(IJSON.fromBin(bin));
	factory PreSyncMsg.fromJson(JSON json) =>
		PreSyncMsg(
			json["peerId"],
			json["sessionId"],
			json["resetCount"],
			protocolVersion: json["protocolVersion"]
		);
}

class SyncMsg<M extends IJSON> extends IJSON {
	
	final List<Event<M>> evs, dels;
	SyncMsg(this.evs, this.dels);

	JSON toJson() => {
		"evs": evs,
		"dels": dels,
	};

	bool get isEmpty => evs.isEmpty && dels.isEmpty;
	bool get isNotEmpty => !isEmpty;

	factory SyncMsg.fromBin(List<int> bin, Reviver<Event<M>> reviver) => SyncMsg.fromJson(IJSON.fromBin(bin), reviver);
	factory SyncMsg.fromJson(JSON json, Reviver<Event<M>> reviver) =>
		SyncMsg(
			jlist_map(json["evs"], reviver),
			jlist_map(json["dels"], reviver),
		);

}

enum PeerState {

	NOCONN,
	PRESYNC,
	CONFLICT,
	SYNC;

	bool get isSync => this == PeerState.SYNC;
	bool get isConflict => this == PeerState.CONFLICT;
	bool get connected => this != PeerState.NOCONN;

}

abstract class Peer {

	int get desyncCount =>
		_man == null ? 0 :
			_man!._em.events.length + _man!._em.deletes.length
			- _lastLocal.evLen - _lastLocal.delLen;

	bool _connected = false;
	bool get connected => __state.connected;
	bool get disconnected => !__state.connected;

	int? get sessionId => _lastKnownState?.sessionId;
	String? get id => _lastKnownState?.peerId;
	PreSyncMsg? _lastKnownState;
	PeerManager? _man;

	PeerState __state = PeerState.NOCONN;
	PeerState get _state => __state;
	set _state (PeerState newState) {
		if (__state != newState) {
			_man?._onStateChange.add(this);
			// print("$id = $newState");
		}
		__state = newState;
	}
	PeerState get state => _state;

	Mutex _mutex = Mutex();
	SyncInfo _lastLocal = SyncInfo.zero();

	/// idempotent
	void setConnected(bool conn) {
		if (conn && !state.connected) {
			_state = PeerState.PRESYNC;
		} else if (!conn) {
			_state = PeerState.NOCONN;
		}
	}

	bool isOutgoing();
	void connect();
	void disconnect();

	Future<List<int>?> send(String msg, List<int> data);
	Future<List<int>?> onRecieve(String msg, List<int> data)
		=> _man?._onRecieve(this, msg, data) ?? Future.value(null);

}

abstract class SyncProtocol {

	/// Current version of the protocol
	static const int VERSION = 1;

	/// SyncMsg payload
	static const String SYNC = "sync";
	/// PreSyncMsg payload
	static const String PRE_SYNC = "presync";
	/// no payload
	static const String ACK_SYNC = "syncack";

	static const List<int> OK = const [1];
	static const List<int> NOT_OK = const [0];

	static Iterable<String> get events => [SYNC, PRE_SYNC, ACK_SYNC];

}

// TODO: deal with exceptions
class PeerManager<M extends IJSON> {

	bool _autoConnect = false;
	bool get autoConnect => _autoConnect;
	set autoConnect(bool val) {
		if (val && !_autoConnect) {
			for (var p in _peers) {
				if (!p.connected) {
					p.connect();
				}
			}
		}
		_autoConnect = val;
	}

	StreamController<Null> _onUpdate = StreamController.broadcast();
	StreamController<int> _onSessionUpdate = StreamController.broadcast();
	StreamController<Peer> _onStateChange = StreamController.broadcast();
	Stream<int> get sessionStream => _onSessionUpdate.stream;
	Stream<Null> get updateStream => _onUpdate.stream;
	Stream<Peer> get peerStateChanges => _onStateChange.stream;

	final String peerId;
	
	late int _sessionId;
	int get sessionId => _sessionId;	
	int _resetCount = Random().nextInt(1 << 30);

	late final EventDatabase<M> _db;
	SyncInfo _lastDbSave = SyncInfo.zero();
	final Mutex _mutex = Mutex();
	List<Peer> _peers = [];
	List<Peer> get peers => _peers;
	late EventModel<M> _em;

	M get model => _em.model;
	ReadOnlyOrderedSet<Event<M>> get events => _em.events;
	Set<Event<M>> get deletes => _em.deletes;

	late final Handle<M> handle;

	PeerManager(
		this.peerId,
		AsyncProducer<EventDatabase<M>> createDb,
      EventModelHandle<M> innerHandle,
	) {
		peerStateChanges.listen(_stateChangeHandler);
		_sessionId = Random().nextInt(1 << 30);
		_onSessionUpdate.add(_sessionId);
		// print("$peerId ses = $_sessionId");
		handle = Handle<M>(
			() => _onUpdate.add(null),
         innerHandle
		);
		_em = EventModel(handle);
		_initDatabase(createDb);
	}

	void _initDatabase(AsyncProducer<EventDatabase<M>> createDb) {
		_mutex.protect(() async {
			_db = await createDb();
			var data = await _db.loadData(this.peerId);
			_em.add(data.a.evs, data.a.dels);
			if (data.b != null) {
				// TODO: _peerId = data.b!.peerId;
				_resetCount = data.b!.resetCount;
				_sessionId = data.b!.sessionId;
				// print("$peerId ses = $_sessionId");
				_onSessionUpdate.add(_sessionId);
			}
			_lastDbSave = _em.syncState;
			await _save();
		});
	}

	Future<void> add(List<Event<M>> evs, [List<Event<M>> dels = const []]) async {
		if (evs.isEmpty && dels.isEmpty) return;
		await _mutex.protect(() async {
			var ss = _em.syncState;
			_em.add(evs, dels);
			if (ss == _em.syncState) return;
			await _save();
			_broadcastSync();
		});
	}

	/// mutex order manager -> all peers
	Future<void> resetSession() async =>
		_mutex.protect(() async {
			await _reset(disconnect: false);
			// print("$peerId ses = $_sessionId");
			for (var op in _peers) {
				op._mutex.protect(() => _preSync(op));
			}
		});
	
	/// mutex order manager -> peer
	Future<void> resetModel() async {
		// print("reset $peerId");
		await _mutex.protect(() async {
			await _db.clear(keepPeers: true);
			_em.reset();
			_resetCount = Random().nextInt(1 << 30);
			for (var p in _peers) {
				p._mutex.protect(() async {
					p._lastLocal = SyncInfo.zero();
					_preSync(p);
				});
			}
		});
	}
	
	/// must have manager lock
	Future<void> _save() async {
		var data = _em.getNewer(_lastDbSave);
		var curState = _em.syncState;
		if (data.isNotEmpty) {
			await _db.add(data);
		}
		await _db.savePeer(_curPreSyncMsg(), SyncInfo.zero());
		_lastDbSave = curState;
		// print("saved $peerId");
	}

	void _broadcastSync() {
		_peers.forEach(_syncTo);
	}

	void _syncTo(Peer p) {
		// print("syncto ${p.id} ${p._state.name}");
		p._mutex.protect(() async {
			if (p._state != PeerState.SYNC) {
				// print("cannot sync to ${p.id} ${p._state.name}");
				return;
			}
			var ss = _em.syncState;
			if (p._lastLocal == ss) {
				// print("nothing to sync with ${p.id}");
				return;
			}
			var data = _em.getNewer(p._lastLocal);
			// print("send ${data.evs} to ${p.id}");
			var res = await p.send(
				SyncProtocol.SYNC,
				data.toJsonBin()
			);
			if (res == null) {
				// timeout
				return;
			}
			p._lastLocal = ss;
		});
	}

	Future<void> addPeer(Peer p) async {
      if (peers.contains(p)) {
         return;
      }
		p._man = this;
		await _mutex.protect(() async {
			_peers.add(p);
			_stateChangeHandler(p);
			if (_autoConnect) {
				p.connect();
			}
		});
	}

	void _stateChangeHandler(Peer p) {
		if (p._connected == p._state.connected) {
			return;
		}
		p._connected = p._state.connected;
		// print("con $peerId -> ${p.id} = ${p._connected}");
		if (p._state == PeerState.PRESYNC && p.isOutgoing()) {
			p._mutex.protect(() => _preSync(p));
		}
	}

	/// must have peer lock
	Future<void> _preSync(Peer p, [bool retry = true]) async {
		// print("presync to ${p.id}");
		if (!p.connected) return;
		p._state = PeerState.PRESYNC;
		var res = await p.send(SyncProtocol.PRE_SYNC, _curPreSyncMsg().toJsonBin());
		if (res == null) {
			// print("no presync ack");
			// TODO: no presync ack (retry?)
			if (retry) return _preSync(p, false);
			return;
		}
		await _handlePreSync(p, PreSyncMsg.fromBin(res));
		if (p._state.isSync) {
			// print("send syncack => ${p.id}");
			p.send(SyncProtocol.ACK_SYNC, []);
			_syncTo(p);
		}
	}

	PreSyncMsg _curPreSyncMsg() =>
		PreSyncMsg(
			peerId,
			_sessionId,
			_resetCount
		);

	/// must have peer lock
	Future<void> _handlePreSync(Peer p, PreSyncMsg ps) async {
		if (ps.protocolVersion != ps.protocolVersion) {
			// print("protocol version conflict");
			return;
		}
		var conflict = _peers.where((p2) => p2.id == ps.peerId && p2 != p).firstOrNull;
		if (conflict != null) {
			_peers.remove(conflict);
			// disconnect ?
		}
		if (p._lastKnownState == null) {
			var state = await _db.loadPeer(ps.peerId);
			p._lastKnownState = state?.a;
			p._lastLocal = state?.b ?? p._lastLocal;
		}
		var last = p._lastKnownState ?? ps;
		if (last.peerId != ps.peerId) {
			// TODO: client changed peer id
		}
		p._lastKnownState = ps;
		// print("handle pre sync from ${ps.peerId}");
		if (ps.sessionId != sessionId) {
			p._state = PeerState.CONFLICT;
			// print("conflict peer:${ps.sessionId} != this:${sessionId}");
			return;
		}
		if (last.resetCount != ps.resetCount || last.sessionId != ps.sessionId) {
			// print("discovered reset by ${ps.peerId}");
			p._lastLocal = SyncInfo.zero();
		}
		p._state = PeerState.SYNC;
		p._lastKnownState = ps;
		_db.savePeer(ps, p._lastLocal);
	}

	Future<List<int>?> _onRecieve(Peer p, String msg, List<int> data) async =>
		p._mutex.protect(() async {
			switch (msg) {
				case SyncProtocol.ACK_SYNC:
					// print("syncack from ${p.id}");
					_syncTo(p);
					return [];
				case SyncProtocol.PRE_SYNC:
					// print("presync from ${p.id}");
					_handlePreSync(p, PreSyncMsg.fromBin(data));
					return _curPreSyncMsg().toJsonBin();
				case SyncProtocol.SYNC:
					if (p._state != PeerState.SYNC) {
						// print("rcv: not in sync yet");
						return null;
					}
					if (p._lastKnownState?.sessionId != _sessionId) {
						// print("sync incorrect session");
						p._state = PeerState.CONFLICT;
						return null;
					}
					var msg = SyncMsg<M>.fromBin(data, handle.reviveEvent);
					var upToDate = _em.syncState == p._lastLocal;
					await add(msg.evs, msg.dels);
					if (upToDate) {
						p._lastLocal = _em.syncState;
					} else {
						_syncTo(p);
					}
					return SyncProtocol.OK;
				default:
					// print("$msg ?");
					return null;
			}
		});

	/// mutex order manager -> all peers
	Future<bool> yieldTo(Peer p) =>
		_mutex.protect(() =>
			p._mutex.protect(() async {
				// print("yield to ${p.id} ${p._state.name} ${p._lastKnownState?.sessionId}");
				if (p.sessionId == sessionId) {
					return false;
				}
				if (p._state != PeerState.CONFLICT) {
					return false;
				}
				await _reset(disconnect: false, ignoreLockFor: p);
				_sessionId = p._lastKnownState!.sessionId;
				_onSessionUpdate.add(_sessionId);
				await _save();
				// print("$peerId ses = $_sessionId");
				for (var op in _peers) {
					op._mutex.protect(() => _preSync(op));
				}
				return true;
			})
		);

	/// must have manager lock, will take all peer locks (except for ignoreLockFor)
	Future<void> _reset({bool keepDatabase = false, bool disconnect = true, bool keepPeerData = true, Peer? ignoreLockFor}) async {
		var locks = _peers
			.where((e) => e != ignoreLockFor)
			.map((p) => p._mutex)
			.toList();
		try {
			await Future.wait(locks.map((l) => l.acquire()));
			// print("reset");
			if (!keepDatabase) {
				await _db.clear(keepPeers: keepPeerData);
			}
			_em.reset();
			_sessionId = Random().nextInt(1 << 30);
			// print("$peerId ses = $_sessionId");
			_resetCount = Random().nextInt(1 << 30);
			for (var p in _peers) {
				if (disconnect) {
					p.disconnect();
				}
				p._lastLocal = SyncInfo.zero();
			}
			_onSessionUpdate.add(_sessionId);
			_onUpdate.add(null);
		}
		catch (e) {
			print(e);
		}
		finally {
			for (var l in locks) {
				l.release();
			}
		}
	}

}

class Handle<M extends IJSON> extends EventModelHandle<M> {

   final EventModelHandle<M> _handle;

	final void Function() onUpdate;

	Handle(this.onUpdate, this._handle);

	@override
	M createModel() => _handle.createModel();
	@override
	M revive(JSON json) => _handle.revive(json);
	@override
	Event<M> reviveEvent(JSON json) =>_handle.reviveEvent(json);

	@override
	void didUpdate() {
      onUpdate();
      _handle.didUpdate();
   }

	@override
	void didReset() {
      onUpdate();
      _handle.didReset();
   }

}

class LocalPeer extends Peer {

	late final LocalPeer _other;
	final bool _outgoing;

	LocalPeer._(this._outgoing) {}
	static Tuple<LocalPeer, LocalPeer> pair() {
		var pair = Tuple(
			LocalPeer._(true),
			LocalPeer._(false),
		);
		pair.a._other = pair.b;
		pair.b._other = pair.a;
		return pair;
	}

	@override
	void connect() {
		setConnected(true);
		_other.setConnected(true);
	}
	@override
	void disconnect() {
		setConnected(false);
		_other.setConnected(false);
	}

	@override
	bool isOutgoing() => _outgoing;

	@override
	Future<List<int>?> send(String msg, List<int> data)
		=> _other.onRecieve(msg, data);

}
