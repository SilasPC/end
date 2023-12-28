import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:mutex/mutex.dart';
import '../util.dart';
import 'db.dart';
import 'protocol.dart';

enum PeerState {
  NOCONN,
  NOSESS,
  PRESYNC,
  CONFLICT,
  SYNC;

  bool get isSync => this == PeerState.SYNC;
  bool get isConflict => this == PeerState.CONFLICT;
  bool get connected => this != PeerState.NOCONN;
}

abstract class Peer {
  int get desyncCount => _man == null
      ? 0
      : _man!._em.events.length +
          _man!._em.deletes.length -
          _lastLocal.evLen -
          _lastLocal.delLen;

  bool _connected = false;
  bool get connected => __state.connected;
  bool get disconnected => !__state.connected;

  Session? get session => _lastKnownState?.session;
  String? get id => _lastKnownState?.identity?.name;
  PeerIdentity? get ident => _lastKnownState?.identity;
  PreSyncMsg? _lastKnownState;
  PeerManager? _man;

  PeerState __state = PeerState.NOCONN;
  PeerState get _state => __state;
  set _state(PeerState newState) {
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
  Future<List<int>?> onRecieve(String msg, List<int> data) =>
      _man?._onRecieve(this, msg, data) ?? Future.value(null);
}

// IGNORED: TODO: deal with exceptions
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
  StreamController<Session?> _onSessionUpdate = StreamController.broadcast();
  StreamController<Peer> _onStateChange = StreamController.broadcast();
  Stream<Session?> get sessionStream => _onSessionUpdate.stream;
  Stream<Null> get updateStream => _onUpdate.stream;
  Stream<Peer> get peerStateChanges => _onStateChange.stream;

  PrivatePeerIdentity? _id;
  PeerIdentity? get id => _id?.identity;

  void changeIdentity(PrivatePeerIdentity? id) {
    if (_id == id) return;
    assert(id?.identity.verifySignature() ?? true, "invalid identity provided");
    if (session case Session(:var root)) {
      assert(id?.identity.isSignedBy(root) ?? true,
          "when in session, provided identity should be signed by session owner");
    }
    _id = id;
    if (id case PrivatePeerIdentity id) {
      _authors[id.identity.name] = id.identity;
    }
    _broadcastPresync();
  }

  Session? _session;
  Session? get session => _session;

  int? get sessionId => _session?.id;
  int _resetCount = Random().nextInt(1 << 30);

  late final EventDatabase<M> _db;
  SyncInfo _lastDbSave = SyncInfo.zero();
  final Mutex _mutex = Mutex();
  List<Peer> _peers = [];
  List<Peer> get peers => _peers;
  late EventModel<M> _em;
  final List<Signature> _eventSignatures = [], _deleteSignatures = [];
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
    if (_id case PrivatePeerIdentity id) {
      _authors[id.identity.name] = id.identity;
    }
    peerStateChanges.listen(_stateChangeHandler);
    _onSessionUpdate.add(_session);
    // print("$peerId ses = $_sessionId");
    handle = Handle<M>(() => _onUpdate.add(null), innerHandle);
    _em = EventModel(handle);
    ready = _initDatabase(createDb);
  }

  Future<void> _initDatabase(AsyncProducer<EventDatabase<M>> createDb) =>
      _mutex.protect(() async {
        _db = await createDb();
        var (syncMsg, preSyncMsg) = await _db.loadData();
        _em.add(syncMsg.evs, syncMsg.dels);
        _eventSignatures.addAll(syncMsg.sigs);
        _deleteSignatures.addAll(syncMsg.delSigs);
        _authors.addEntries(syncMsg.authors.map((id) => MapEntry(id.name, id)));
        if (preSyncMsg case PreSyncMsg preSyncMsg) {
          _resetCount = preSyncMsg.resetCount;
          _session = preSyncMsg.session;
          // print("$peerId ses = $_sessionId");
          _onSessionUpdate.add(_session);
        }
        _lastDbSave = _em.syncState;
        await _save();
      });

  Future<void> add(List<Event<M>> evs, [List<Event<M>> dels = const []]) async {
    assert(_id != null, "add() called without assigned identity");
    PrivatePeerIdentity theAuthor = _id!;
    assert(!evs.any((e) => e.author != theAuthor.identity.name),
        "event authors must match identity for signing");
    assert(!dels.any((e) => e.author != theAuthor.identity.name),
        "event authors must match identity for signing");
    var signer = theAuthor.signer;
    _addSigned(evs, dels, evs.map((e) => signer.sign(e.toJsonBytes())).toList(),
        dels.map((e) => signer.sign([0, ...e.toJsonBytes()])).toList());
  }

  Future<void> _addSigned(List<Event<M>> evs, List<Event<M>> dels,
      List<Signature> signatures, List<Signature> delSignatures) async {
    assert(evs.length == signatures.length);
    assert(dels.length == delSignatures.length);
    if (evs.isEmpty && dels.isEmpty) return;
    await _mutex.protect(() async {
      var ss = _em.syncState;
      _em.add(evs, dels);
      _eventSignatures.addAll(signatures);
      _deleteSignatures.addAll(delSignatures);
      if (ss == _em.syncState) return;
      await _save();
      _broadcastSync();
    });
    return;
  }

  /// mutex order manager -> all peers
  Future<bool> createSession() async => _mutex.protect(() async {
        var id = this.id;
        if (id == null) return false;
        await _reset(disconnect: false, newSession: Session.newSession(id));
        // print("$peerId ses = $_sessionId");
        _broadcastPresync();
        return true;
      });

  /// mutex order manager -> all peers
  Future<void> leaveSession() async => _mutex.protect(() async {
        await _reset(disconnect: false, newSession: null);
        // print("$peerId ses = $_sessionId");
        _broadcastPresync();
      });

  /// mutex order manager -> peer
  Future<void> resetModel() async {
    // print("reset $peerId");
    await _mutex.protect(() async {
      await _db.clear(keepPeers: true);
      _em.reset();
      _eventSignatures.clear();
      _deleteSignatures.clear();
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
      _deleteSignatures.sublist(info.delLen),
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
    await _db.saveData(_curPreSyncMsg());
    _lastDbSave = curState;
    // print("saved $peerId");
  }

  void _broadcastSync() {
    _peers.forEach(_syncTo);
  }

  void _broadcastPresync() {
    for (var op in _peers) {
      op._mutex.protect(() => _preSync(op));
    }
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
      var res = await p.send(SyncProtocol.SYNC, data.toJsonBin());
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
      if (peers.contains(p)) {
        return;
      }
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

  PreSyncMsg _curPreSyncMsg() => PreSyncMsg(id, _session, _resetCount);

  /// must have peer lock
  Future<void> _handlePreSync(Peer p, PreSyncMsg ps) async {
    if (ps.protocolVersion != ps.protocolVersion) {
      // print("protocol version conflict");
      return;
    }
    /* var conflict =
        _peers.where((p2) => p2.id == ps.identity.name && p2 != p).firstOrNull;
    if (conflict != null) {
      _peers.remove(conflict);
      // disconnect ?
    }*/
    if (ps.identity?.name case String name when p._lastKnownState == null) {
      if (await _db.loadPeer(name) case (var preSyncMsg, var syncInfo)) {
        p._lastKnownState = preSyncMsg;
        p._lastLocal = syncInfo;
      }
    }
    if (p._lastKnownState?.identity != ps.identity) {
      // print("change id");
      if (ps.identity case PeerIdentity id) {
        if (!id.verifySignature()) {
          // print("bad certificate");
          p.disconnect();
          return;
        }
        if (session case Session(:var root)) {
          if (!id.isSignedBy(root)) {
            // print("untrusted signer");
            // TODO: correct?
            p._state = PeerState.CONFLICT;
            return;
          }
        }
      }
    }
    var prevState = p._lastKnownState ?? ps;
    p._lastKnownState = ps;
    // print("handle pre sync from ${ps.identity}");
    if (!Session.nullEq(ps.session, session)) {
      p._state = ps.session == null ? PeerState.NOSESS : PeerState.CONFLICT;
      // print("conflict peer:${ps.session} != this:${session}");
      return;
    }
    if (prevState.resetCount != ps.resetCount) {
      // print("discovered reset by ${ps.identity}");
      p._lastLocal = SyncInfo.zero();
    }
    p._state = PeerState.SYNC;
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
            if (!Session.nullEq(p._lastKnownState?.session, _session)) {
              // print("sync incorrect session");
              p._state = PeerState.CONFLICT;
              return null;
            }
            var msg = SyncMsg<M>.fromBin(data, handle.reviveEvent);
            if (!_verifySyncMsg(msg)) {
              p.disconnect();
              return null;
            }
            var upToDate = _em.syncState == p._lastLocal;
            await _addSigned(msg.evs, msg.dels, msg.sigs, msg.delSigs);
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
      _mutex.protect(() => p._mutex.protect(() async {
            // print("yield to ${p.id} ${p._state.name} ${p._lastKnownState?.session}");
            if (p.session == null ||
                Session.nullEq(p.session, session) ||
                p._state != PeerState.CONFLICT) {
              return false;
            }
            await _reset(
                disconnect: false, ignoreLockFor: p, newSession: p.session!);
            await _save();
            // print("$peerId ses = $_sessionId");
            _broadcastPresync();
            return true;
          }));

  /// must have manager lock, will take all peer locks (except for ignoreLockFor)
  Future<void> _reset(
      {bool keepDatabase = false,
      bool disconnect = true,
      bool keepPeerData = true,
      Peer? ignoreLockFor,
      required Session? newSession}) async {
    var locks =
        _peers.where((e) => e != ignoreLockFor).map((p) => p._mutex).toList();
    try {
      await Future.wait(locks.map((l) => l.acquire()));
      // print("reset");
      if (!keepDatabase) {
        await _db.clear(keepPeers: keepPeerData);
        _lastDbSave = SyncInfo.zero();
      }
      if (!keepPeerData) {
        _authors.clear();
        if (id case PeerIdentity id) {
          _authors[id.name] = id;
        }
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
      _deleteSignatures.clear();
      _resetCount = Random().nextInt(1 << 30);
      _session = newSession;
      _onSessionUpdate.add(_session);
      _onUpdate.add(null);
    } catch (e) {
      // print(e);
    } finally {
      for (var l in locks) {
        l.release();
      }
    }
  }

  /// verify that the sync msg is not malicious
  bool _verifySyncMsg(SyncMsg<M> msg) {
    if (msg.sigs.length != msg.evs.length ||
        msg.dels.length != msg.delSigs.length) {
      // print("bad sync");
      return false;
    }
    for (var author in msg.authors) {
      if (_authors.containsKey(author.name)) {
        continue;
      }
      if (!author.verifySignature()) {
        // print("bad author certificate");
        return false;
      }
      if (!author.isSignedBy(session!.root)) {
        // print("untrusted signer");
        return false;
      }
      _authors[author.name] = author;
    }
    for (int i = 0; i < msg.evs.length; i++) {
      var ev = msg.evs[i];
      var sig = msg.sigs[i];
      var ok = _authors[ev.author]!.verifier.verify(ev.toJsonBytes(), sig);
      if (!ok) {
        // print("bad event signature");
        // print(ev.author);
        // print(_authors[ev.author]);
        return false;
      }
    }
    for (int i = 0; i < msg.dels.length; i++) {
      var ev = msg.dels[i];
      var sig = msg.delSigs[i];
      var ok = _authors[ev.author]!
          .verifier
          .verify(Uint8List.fromList([0, ...ev.toJsonBytes()]), sig);
      if (!ok) {
        // print("bad event signature");
        // print(ev.author);
        // print(_authors[ev.author]);
        return false;
      }
    }
    return true;
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
  Event<M> reviveEvent(JSON json) => _handle.reviveEvent(json);

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
    // print("manual disconnect by $id");
    setConnected(false);
    _other.setConnected(false);
  }

  @override
  bool isOutgoing() => _outgoing;

  @override
  Future<List<int>?> send(String msg, List<int> data) =>
      _other.onRecieve(msg, data);
}
