
import 'dart:async';
import 'dart:math';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:mutex/mutex.dart';
import '../util.dart';
import 'db.dart';
import 'protocol.dart';

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
	String? get id => _lastKnownState?.identity.name;
	PeerIdentity? get ident => _lastKnownState?.identity;
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

   final PeerIdentity _trustAnchor = PeerIdentity.server();
	final PrivatePeerIdentity _id;
	PeerIdentity get id => _id.identity;

	late int _sessionId;
	int get sessionId => _sessionId;
	int _resetCount = Random().nextInt(1 << 30);

	late final EventDatabase<M> _db;
	SyncInfo _lastDbSave = SyncInfo.zero();
	final Mutex _mutex = Mutex();
	List<Peer> _peers = [];
	List<Peer> get peers => _peers;
	late EventModel<M> _em;
	final List<Signature> _eventSignatures = [];
	final Map<String, PeerIdentity> _authors = {};

	M get model => _em.model;
	ReadOnlyOrderedSet<Event<M>> get events => _em.events;
	Set<Event<M>> get deletes => _em.deletes;

	late final Handle<M> handle;

	late final Future<void> ready;

	PeerManager(
		this._id,
		AsyncProducer<EventDatabase<M>> createDb,
		EventModelHandle<M> innerHandle,
	) {
		_authors[id.name] = id;
		peerStateChanges.listen(_stateChangeHandler);
		_sessionId = Random().nextInt(1 << 30);
		_onSessionUpdate.add(_sessionId);
		// print("$peerId ses = $_sessionId");
		handle = Handle<M>(
			() => _onUpdate.add(null),
			innerHandle
		);
		_em = EventModel(handle);
		ready = _initDatabase(createDb);
	}

	Future <void> _initDatabase(AsyncProducer<EventDatabase<M>> createDb) =>
		_mutex.protect(() async {
			_db = await createDb();
			var (syncMsg, preSyncMsg) = await _db.loadData(this.id.name);
			_em.add(syncMsg.evs, syncMsg.dels);
			_eventSignatures.addAll(syncMsg.sigs);
			_authors.addEntries(
				syncMsg.authors.map((id) => MapEntry(id.name, id))
			);
			if (preSyncMsg case PreSyncMsg preSyncMsg) {
				_resetCount = preSyncMsg.resetCount;
				_sessionId = preSyncMsg.sessionId;
				// print("$peerId ses = $_sessionId");
				_onSessionUpdate.add(_sessionId);
			}
			_lastDbSave = _em.syncState;
			await _save();
		});

	Future<void> add(List<Event<M>> evs, [List<Event<M>> dels = const [], PrivatePeerIdentity? author]) async {
		var theAuthor = author ?? _id;
		if (evs.any((e) => e.author != theAuthor.identity.name)) {
			throw Exception("event authors must match manager identifier for signing");
		}
		var signer = theAuthor.signer;
		_addSigned(evs, dels, evs.map((e) => signer.sign(e.toJsonBin())).toList());
	}

	Future<void> _addSigned(List<Event<M>> evs, List<Event<M>> dels, List<Signature> signatures) async {
		if (evs.isEmpty && dels.isEmpty) return;
		await _mutex.protect(() async {
			var ss = _em.syncState;
			_em.add(evs, dels);
			_eventSignatures.addAll(signatures);
			if (ss == _em.syncState) return;
			await _save();
			_broadcastSync();
		});
		return;
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
			_eventSignatures.clear();
			_resetCount = Random().nextInt(1 << 30);
			for (var p in _peers) {
				p._mutex.protect(() async {
					p._lastLocal = SyncInfo.zero();
					_preSync(p);
				});
			}
		});
	}

	SyncMsg<M> _syncMsg(SyncInfo info) {
		var (evs, dels) = _em.getNewer(info);
		return SyncMsg(
			evs,
			dels,
			_eventSignatures.sublist(info.evLen),
			evs.map((e) => _authors[e.author]!).toSet().toList(),
		);
	}

	/// must have manager lock
	Future<void> _save() async {
		var data = _syncMsg(_lastDbSave);
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
			var data = _syncMsg(p._lastLocal);
			// print("send ${data.toJsonString()} to ${p.id}");
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
			if (retry) return _preSync(p, false);
			p.disconnect();
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
			id,
			_sessionId,
			_resetCount
		);

	/// must have peer lock
	Future<void> _handlePreSync(Peer p, PreSyncMsg ps) async {
		if (ps.protocolVersion != ps.protocolVersion) {
			// print("protocol version conflict");
			return;
		}
		var conflict = _peers.where((p2) => p2.id == ps.identity.name && p2 != p).firstOrNull;
		if (conflict != null) {
			_peers.remove(conflict);
			// disconnect ?
		}
		if (p._lastKnownState == null) {
			if (await _db.loadPeer(ps.identity.name) case (var preSyncMsg, var syncInfo)) {
				p._lastKnownState = preSyncMsg;
				p._lastLocal = syncInfo;
			}
		}
		var prevState = p._lastKnownState ?? ps;
		if (prevState.identity.name != ps.identity.name) {
			// TODO: client changed peer id
			unimpl("idk what to do here yet");
			return;
		}
		assert(prevState.identity.isSameAs(ps.identity));
		if (p._lastKnownState == null) {
			// print("check certificate ${ps.identity}");
			// note: this check does not run when loaded from database
			if (!ps.identity.verifySignature(_trustAnchor.key)) {
				// print("bad certificate");
				return;
			}
		}
		p._lastKnownState = ps;
		// print("handle pre sync from ${ps.peerId}");
		if (ps.sessionId != sessionId) {
			p._state = PeerState.CONFLICT;
			// print("conflict peer:${ps.sessionId} != this:${sessionId}");
			return;
		}
		if (prevState.resetCount != ps.resetCount || prevState.sessionId != ps.sessionId) {
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
					if (msg.sigs.length != msg.evs.length) {
						p.disconnect();
						return null;
					}
					for (var author in msg.authors) {
						if (_authors.containsKey(author.name)) {
							continue;
						}
						if (!author.verifySignature(_trustAnchor.key)) {
							// print("bad author certificate")
							p.disconnect();
							return null;
						}
						_authors[author.name] = author;
					}
					for (int i = 0; i < msg.evs.length; i++) {
						var ev = msg.evs[i];
						var sig = msg.sigs[i];
						var ok = _authors[ev.author]!.verifier.verify(ev.toJsonBytes(), sig);
						if (!ok) {
							// print("bad event signature");
							p.disconnect();
							return null;
						}
					}
					await _addSigned(msg.evs, msg.dels, msg.sigs);
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
				if (p.sessionId == null || p.sessionId == sessionId || p._state != PeerState.CONFLICT) {
					return false;
				}
				await _reset(disconnect: false, ignoreLockFor: p, newSession: p.sessionId!);
				await _save();
				// print("$peerId ses = $_sessionId");
				for (var op in _peers) {
					op._mutex.protect(() => _preSync(op));
				}
				return true;
			})
		);

	/// must have manager lock, will take all peer locks (except for ignoreLockFor)
	Future<void> _reset({
		bool keepDatabase = false,
		bool disconnect = true,
		bool keepPeerData = true,
		Peer? ignoreLockFor,
		int? newSession
	}) async {
		var locks = _peers
			.where((e) => e != ignoreLockFor)
			.map((p) => p._mutex)
			.toList();
		try {
			await Future.wait(locks.map((l) => l.acquire()));
			// print("reset");
			if (!keepDatabase) {
				await _db.clear(keepPeers: keepPeerData);
				_lastDbSave = SyncInfo.zero();
			}
			if (!keepPeerData) {
				_authors.clear();
				_authors[id.name] = id;
			}
			// print("$peerId ses = $_sessionId");
			for (var p in _peers) {
				if (disconnect) {
					p.disconnect();
				}
				p._lastLocal = SyncInfo.zero();
			}
			_em.reset();
			_eventSignatures.clear();
			_resetCount = Random().nextInt(1 << 30);
			_sessionId = newSession ?? Random().nextInt(1 << 30);
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

class DummyPeer extends Peer {
   @override
   void connect() {}

   @override
   void disconnect() {}

   @override
   bool isOutgoing() => true;

   @override
   Future<List<int>?> send(String msg, List<int> data) async => null;
}

class LocalPeer extends Peer {

	late final LocalPeer _other;
	final bool _outgoing;

	LocalPeer._(this._outgoing) {}
	static (LocalPeer, LocalPeer) pair() {
		var pair = (
			LocalPeer._(true),
			LocalPeer._(false),
		);
		pair.$1._other = pair.$2;
		pair.$2._other = pair.$1;
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
