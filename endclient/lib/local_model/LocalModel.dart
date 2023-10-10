
// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/sqlite_db.dart';
import 'package:esys_client/p2p/ServerPeer.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ModelProvider extends StatelessWidget {
	const ModelProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<Settings, LocalModel>(
			lazy: false,
			create: (_) => LocalModel(),
			update: (_, set, mod) {
				mod!.setServerUri(set.serverURI);
				mod.autoYield = set.autoYield;
				return mod;
			},
			child: child,
		);
}

class LocalModel with ChangeNotifier {

	bool _autoYield = false;
	bool get autoYield => _autoYield;
	set autoYield (bool value) {
		if (!_autoYield && value) {
			if (master?.state.isConflict ?? false) {
				manager.yieldTo(master!);
			}
		}
		_autoYield = value;
	}

	late PeerManager<Model> manager;
	ServerPeer? master;
	StreamSubscription? _masterConnectSub, _stateChangeSub;

	StreamController<void> serverUpdateStream = StreamController.broadcast();

	LocalModel() {
		manager = PeerManager(
			Platform.localHostname,
			SqliteDatabase.create,
			Model.fromJson,
			EnduranceEvent.fromJson,
			Model.new,
		);
		manager.updateStream.listen((_) => notifyListeners());
	}

	void setServerUri(String uri) {
		if (master?.uri == uri) {
			return;
		}
		master?.disconnect();
		master = ServerPeer(uri);
		_masterConnectSub?.cancel();
		_stateChangeSub?.cancel();
		_masterConnectSub = master!.connectStatus
			.listen((value) => serverUpdateStream.add(null));
		_stateChangeSub = manager.peerStateChanges
			.listen((peer) {
				if (peer != master) return;
				if (peer.state.isConflict && _autoYield) {
					manager.yieldTo(master!);
				}
				serverUpdateStream.add(null);
			});
		manager.addPeer(master!);
		notifyListeners();
		serverUpdateStream.add(null);
	}

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []])
		=> manager.add(evs, dels);

	Set<Event<Model>> get deletes => manager.deletes;

	int get desyncCount => master?.desyncCount ?? 0;

	ReadOnlyOrderedSet<Event<Model>> get events => manager.events;

	Model get model => manager.model;

}