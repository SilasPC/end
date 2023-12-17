
import 'dart:async';

import 'package:common/p2p/Manager.dart';
import 'package:esys_client/p2p/server_peer.dart';
import 'package:flutter/material.dart';


class ServerConnection extends ChangeNotifier {

	bool _autoYield = false;
	bool get autoYield => _autoYield;
	set autoYield (bool value) {
		if (!_autoYield && value) {
			if (_peer case Peer master when master.state.isConflict) {
				_manager.yieldTo(master);
			}
		}
		_autoYield = value;
	}

	ServerPeer? get peer => _peer;
	PeerState? get state => peer?.state;
	bool get connected => peer?.connected ?? false;
	int? get sessionId => peer?.sessionId;
	bool get inSync => state?.isSync ?? false;
	int get desyncCount => peer?.desyncCount ?? 0;

   final PeerManager _manager;

   ServerPeer? _peer;
	StreamSubscription? _stateChangeSub;

   ServerConnection(this._manager) {
      _stateChangeSub = _manager.peerStateChanges
         .where((p) => p == peer)
         .listen((peer) {
				if (peer.state.isConflict && _autoYield) {
					_manager.yieldTo(peer);
				}
         });
   }

	@override
	void dispose() {
		super.dispose();
		_stateChangeSub?.cancel();
	}

	void setServerUri(String uri) {
		if (_peer?.uri == uri) {
			return;
		}
		_peer?.disconnect();
		_manager.addPeer(_peer = ServerPeer(uri));
		notifyListeners();
	}

	Future<bool> yieldRemote() async {
		var res = await peer?.send("yield", []);
		return res?.firstOrNull == 1;
	}

}

class PeerStates extends ChangeNotifier {

	List<Peer> get peers => _manager.peers;

	late StreamSubscription _sub;

	final PeerManager _manager;
	PeerStates(this._manager) {
		_sub = _manager.peerStateChanges.listen((_) {
			notifyListeners();
		});
	}

	@override
	void dispose() {
		super.dispose();
		_sub.cancel();
	}

}

class SessionState extends ChangeNotifier {

	int get sessionId => _manager.sessionId;

	late StreamSubscription _sub;

	final PeerManager _manager;
	SessionState(this._manager) {
		_sub = _manager.sessionStream.listen((_) {
			notifyListeners();
		});
	}

	void reset() => _manager.resetSession();

	@override
	void dispose() {
		super.dispose();
		_sub.cancel();
	}

}
