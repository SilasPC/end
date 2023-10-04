
import 'dart:async';
import 'dart:math';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:mutex/mutex.dart';
import '../util.dart';
import 'db.dart';

class PreSyncMsg extends IJSON {

	final String peerId;
	final int sessionId;
	// TODO: resetCount is somewhat flawed, if session is switched like ABA
	final int resetCount;
	PreSyncMsg(this.peerId, this.sessionId, this.resetCount);
	
	JSON toJson() => {
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
		);
}

class SyncMsg<M extends IJSON> extends IJSON {
	final List<Event<M>> evs, dels;
	SyncMsg(this.evs, this.dels);

	JSON toJson() => {
		"evs": evs,
		"dels": dels,
	};

	factory SyncMsg.fromBin(List<int> bin, Reviver<Event<M>> reviver) => SyncMsg.fromJson(IJSON.fromBin(bin), reviver);
	factory SyncMsg.fromJson(JSON json, Reviver<Event<M>> reviver) =>
		SyncMsg(
			jlist_map(json["evs"], reviver),
			jlist_map(json["dels"], reviver),
		);

}

enum PeerState {
	PRESYNC,
	SYNCERR,
	SYNC;

	bool get isSync => this == PeerState.SYNC;

}

class ConnectNotifier with Stream<bool> {

	bool _value = false;
	StreamController<bool> _stream = StreamController.broadcast();

	bool get value => _value;
	set value (val) {
		if (val != _value)
			_stream.add(val);
		_value = val;
	}

	void add(bool val) {
		value = val;
	}

	@override
	StreamSubscription<bool> listen(
		void Function(bool event)? onData, {
			Function? onError,
			void Function()? onDone,
			bool? cancelOnError
		}
	) {
			scheduleMicrotask(() => onData?.call(_value));
			return _stream.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
	}

}

// TODO: composition over inheritance
abstract class Peer {

	int get desyncCount =>
		_man._em.events.length + _man._em.deletes.length
		- _lastLocal.evLen - _lastLocal.delLen;

	bool _connected = false;
	bool get connected => _connected;
	final ConnectNotifier connectStatus = ConnectNotifier();

	String? get id => _lastKnownState?.peerId;
	PreSyncMsg? _lastKnownState;
	late final PeerManager _man;

	PeerState _state = PeerState.PRESYNC;
	PeerState get state => _state;

	Mutex _mutex = Mutex();
	SyncInfo _lastLocal = SyncInfo.zero();

	bool isOutgoing();
	void connect();
	void disconnect();

	Future<List<int>?> send(String msg, List<int> data);
	Future<List<int>?> onRecieve(String msg, List<int> data)
		=> _man._onRecieve(this, msg, data);

}

abstract class SyncProtocol {
	
	/// SyncMsg payload
	static const String SYNC = "sync";
	/// PreSyncMsg payload
	static const String PRE_SYNC = "presync";
	/// no payload
	static const String ACK_SYNC = "syncack";

	static Iterable<String> get events => [SYNC, PRE_SYNC, ACK_SYNC];

}

// TODO: deal with exceptions
// TODO: should master be considered special?
// TODO: make database a peer?
class PeerManager<M extends IJSON> {

	bool _autoConnect = false;
	bool get autoConnect => _autoConnect;
	set autoConnect(bool val) {
		if (val && !_autoConnect) {
			// TODO: connect to all peers
		}
		_autoConnect = val;
	}

	StreamController<void> _onUpdate = StreamController.broadcast();
	Stream<void> get updateStream => _onUpdate.stream;

	final String peerId;
	
	late int _sessionId;
	int get sessionId => _sessionId;	
	int _resetCount = 0;

	late final EventDatabase<M> _db;
	SyncInfo _lastDbSave = SyncInfo.zero();
	final Mutex _mutex = Mutex();
	List<Peer> _peers = [];
	List<Peer> get peers => _peers;
	Peer? master = null;
	late EventModel<M> _em;

	M get model => _em.model;
	ReadOnlyOrderedSet<Event<M>> get events => _em.events;
	Set<Event<M>> get deletes => _em.deletes;

	late final Handle<M> handle;

	PeerManager(
		this.peerId,
		AsyncProducer<EventDatabase<M>> createDb,
		Reviver<M> reviver,
		Reviver<Event<M>> eventReviver,
		Producer<M> producer,
		[int? sessionId]
	) {
		_sessionId = sessionId ?? Random().nextInt(1 << 30);
		handle = Handle<M>(
			() => _onUpdate.add(null),
			producer,
			reviver,
			eventReviver,
		);
		_em = EventModel(handle);
		_initDatabase(createDb);
	}

	void _initDatabase(AsyncProducer<EventDatabase<M>> createDb) {
		_mutex.protect(() async {
			_db = await createDb();
			var data = await _db.loadData();
			_em.add(data.a.evs, data.a.dels);
			if (data.b != null) {
				// _peerId = data.b!.peerId;
				// _sessionId = data.b!.sessionId;
				// _resetCount = data.c!.resetCount;
			}
			_lastDbSave = _em.syncState;
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
	
	/// mutex order manager -> peer
	Future<void> resetModel() async {
		print("reset $peerId");
		await _mutex.protect(() async {
			await _db.clear(keepPeers: true);
			_em.reset();
			_resetCount++;
			for (var p in _peers) {
				p._mutex.protect(() async {
					p._lastLocal = SyncInfo.zero();
					_preSync(p);
				});
			}
		});
	}

	Future<void> _save() async {
		var data = _em.getNewerData(_lastDbSave);
		var curState = _em.syncState;
		await _db.add(SyncMsg(data.events, data.deletes));
		_lastDbSave = curState;
		print("saved $peerId");
	}

	void _broadcastSync() {
		_peers.forEach(_syncTo);
	}

	void _syncTo(Peer p) {
		print("syncto ${p._lastKnownState?.peerId} ${p._state.name}");
		p._mutex.protect(() async {
			if (p._state != PeerState.SYNC) {
				print("cannot sync to ${p._lastKnownState?.peerId} ${p._state.name}");
				return;
			}
			var ss = _em.syncState;
			if (p._lastLocal == ss) {
				print("nothing to sync with ${p._lastKnownState?.peerId}");
				return;
			}
			var data = _em.getNewerData(p._lastLocal);
			print("send ${data.events} to ${p._lastKnownState?.peerId}");
			var res = await p.send(
				SyncProtocol.SYNC,
				SyncMsg(data.events, data.deletes).toJsonBin()
			);
			if (res == null) {
				// timeout
				return;
			}
			p._lastLocal = ss;
		});
	}

	Future<void> setMaster(Peer p) async {
		p._man = this;
		await _mutex.protect(() async {
			if (master != null) {
				// TODO: consult database for last known state
				// TODO: reset and stuff (?)
			}
			// _reset(); // TODO: don't always do this
			master = p;
			_peers.add(p);
			_bindConnectHandler(p);
			p.connect();
		});
	}

	Future<void> addPeer(Peer p) async {
		p._man = this;
		await _mutex.protect(() async {
			// TODO: consult database for last known state
		});
		_peers.add(p);
		_bindConnectHandler(p);
		if (_autoConnect) {
			p.connect();
		}
	}

	void _bindConnectHandler(Peer p) {
		p.connectStatus.listen((connected) {
			if (p._connected == connected) {
				return;
			}
			print("con $peerId -> ${p._lastKnownState?.peerId} = $connected");
			p._connected = connected;
			if (connected && p.isOutgoing()) {
				p._mutex.protect(() => _preSync(p));
			} else if (!connected) {
				print("set presync ${p._lastKnownState?.peerId}");
				p._state = PeerState.PRESYNC;
			}
		});
	}

	/// must have peer lock
	Future<void> _preSync(Peer p) async {
		print("presync to ${p._lastKnownState?.peerId}");
		p._state = PeerState.PRESYNC;
		var res = await p.send(SyncProtocol.PRE_SYNC, _curPreSyncMsg().toJsonBin());
		if (res == null) {
			print("null presync ack");
			// TODO: ??
			return;
		}
		await _handlePreSync(p, PreSyncMsg.fromBin(res));
		if (p._state.isSync) {
			// TODO: await this: ?
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
		if (p._lastKnownState == null) {
			var state = await _db.loadPeer(ps.peerId);
			// TODO: refactor peer to do this
		}
		var last = p._lastKnownState ?? ps;
		p._lastKnownState = ps;
		print("handle pre sync from ${ps.peerId}");
		if (ps.sessionId != sessionId) {
			print("set syncerr ${ps.peerId}");
			p._state = PeerState.SYNCERR;
			print("conflict ${ps.sessionId} != ${sessionId}");
			// TODO: conflict
			return;
		}
		if (last.resetCount != ps.resetCount || last.sessionId != ps.sessionId) {
			print("discovered reset by ${ps.peerId}");
			p._lastLocal = SyncInfo.zero();
		}
		print("set sync ${ps.peerId}");
		p._state = PeerState.SYNC;
		p._lastKnownState = ps;
	}

	/// must have peer lock (when sending)
	Future<List<int>?> _onRecieve(Peer p, String msg, List<int> data) async {
		switch (msg) {
			case SyncProtocol.ACK_SYNC:
				print("syncack from ${p._lastKnownState?.peerId}");
				_syncTo(p);
				return [];
			case SyncProtocol.PRE_SYNC:
				_handlePreSync(p, PreSyncMsg.fromBin(data));
				return _curPreSyncMsg().toJsonBin();
			case SyncProtocol.SYNC:
				if (p._state != PeerState.SYNC) {
					print("rcv: not in sync yet");
					return null;
				}
				if (p._lastKnownState?.sessionId != _sessionId) {
					print("sync incorrect session");
					// TODO: handle conflict, change state?
					return null;
				}
				var msg = SyncMsg<M>.fromBin(data, handle.eventReviver);
				var upToDate = _em.syncState == p._lastLocal;
				await add(msg.evs, msg.dels);
				if (upToDate) {
					p._lastLocal = _em.syncState;
				} else {
					_syncTo(p);
				}
				return []; // TODO: ack ok?
			default:
				print("$msg ?");
				return null;
		}
	}

	/// mutex order manager -> peer
	Future<bool> yieldTo(Peer p) =>
		_mutex.protect(() =>
			p._mutex.protect(() async {
				print("yield to ${p._lastKnownState?.peerId} ${p._state.name} ${p._lastKnownState?.sessionId}");
				if (p._state != PeerState.SYNCERR) {
					return false;
				}
				await _reset(disconnect: false);
				_sessionId = p._lastKnownState!.sessionId;
				for (var op in _peers) {
					if (op == p) continue;
					op._mutex.protect(() => _preSync(op));
				}
				await _preSync(p);
				return true;
			})
		);

	/// must have manager lock
	Future<void> _reset({bool keepDatabase = false, bool disconnect = true, bool keepPeerData = true}) async {
		print("reset");
		if (!keepDatabase) {
			await _db.clear(keepPeers: keepPeerData);
		}
		_em.reset();
		_sessionId = Random().nextInt(1 << 30);
		_resetCount = 0;
		if (disconnect) {
			for (var p in _peers) {
				p.disconnect();
			}
		}
	}

}

class Handle<M extends IJSON> extends EventModelHandle<M> {

	final void Function() onUpdate;
	final Reviver<M> reviver;
	final Reviver<Event<M>> eventReviver;
	final Producer<M> create;

	Handle(this.onUpdate, this.create, this.reviver, this.eventReviver);

	@override
	M createModel() => create();
	@override
	M revive(JSON json) => reviver(json);
	@override
	Event<M> reviveEvent(JSON json) => eventReviver(json);
	@override
	void didUpdate() => onUpdate();
	@override
	void didReset() => onUpdate();

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
		connectStatus.add(true);
		_other.connectStatus.add(true);
	}
	@override
	void disconnect() {
		connectStatus.add(false);
		_other.connectStatus.add(false);
	}

	@override
	bool isOutgoing() => _outgoing;

	@override
	Future<List<int>?> send(String msg, List<int> data)
		=> _other.onRecieve(msg, data);

}
