
import 'dart:async';
import 'dart:io';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/sqlite_db.dart';
import 'package:esys_client/p2p/ServerPeer.dart';
import 'package:flutter/widgets.dart';

part 'states.dart';

class LocalModel with ChangeNotifier {

	bool _autoYield = false;
	bool get autoYield => _autoYield;
	set autoYield (bool value) {
		if (!_autoYield && value) {
			if (_master?.state.isConflict ?? false) {
				manager.yieldTo(_master!);
			}
		}
		_autoYield = value;
	}

	final MetaModel metaModel = MetaModel() ;

	late PeerManager<Model> manager;
	ServerPeer? _master;
	StreamSubscription? _stateChangeSub;

	StreamController<void> serverUpdateStream = StreamController.broadcast();

	LocalModel() {
		manager = PeerManager(
			Platform.localHostname,
			SqliteDatabase.create,
			metaModel,
		);
		manager.updateStream.listen((_) => notifyListeners());
		_stateChangeSub = manager.peerStateChanges
			.where((p) => p == _master)
			.listen((master) {
				if (master.state.isConflict && _autoYield) {
					manager.yieldTo(master);
				}
				serverUpdateStream.add(null);
			});
	}

	@override
	void dispose() {
		super.dispose();
		_stateChangeSub?.cancel();
	}

	void setServerUri(String uri) {
		if (_master?.uri == uri) {
			return;
		}
		_master?.disconnect();
		_master = ServerPeer(uri);
		manager.addPeer(_master!);
		notifyListeners();
		serverUpdateStream.add(null);
	}

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []])
		=> manager.add(evs, dels);

	Set<Event<Model>> get deletes => manager.deletes;

	ReadOnlyOrderedSet<Event<Model>> get events => manager.events;

	Model get model => manager.model;

	void resetModel() => manager.resetModel();

}
