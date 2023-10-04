
import 'dart:async';
import 'dart:io';

import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/MasterPeer.dart';
import 'package:esys_client/local_model/database.dart';
import 'package:flutter/foundation.dart';

class PeerManagedModel with ChangeNotifier implements LocalModel {

	late PeerManager<Model> manager;
	final ValueNotifier<bool> _connection = ValueNotifier(false);
	ServerPeer? master;
	StreamSubscription? _masterConnectSub;

	PeerManagedModel() {
		manager = PeerManager(
			Platform.localHostname,
			SqfliteDatabase.create,
			Model.fromJson,
			EnduranceEvent.fromJson,
			Model.new,
		);
		manager.updateStream.listen((_) => notifyListeners());
	}

	@override
	void setServerUri(String uri) {
		if (master?.uri == uri) {
			return;
		}
		master?.disconnect();
		master = ServerPeer(uri);
		_masterConnectSub?.cancel();
		_masterConnectSub = master!.connectStatus
			.listen((value) => _connection.value = value);
		manager.addPeer(master!);
		notifyListeners();
	}

	@override
	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []])
		=> manager.add(evs, dels);

	@override
	ValueNotifier<bool> get connection => _connection;

	@override
	Set<Event<Model>> get deletes => manager.deletes;

	@override
	int get desyncCount => master?.desyncCount ?? 0;

	@override
	ReadOnlyOrderedSet<Event<Model>> get events => manager.events;

	@override
	Model get model => manager.model;

	@override
	Future<void> resetSync() => manager.resetModel();

}
