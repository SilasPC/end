
import 'package:common/p2p/Manager.dart';

import '../event_model/EventModel.dart';
import '../util.dart';

abstract class EventDatabase<M extends IJSON> {
	SyncInfo lastSaved();
	Future<void> add(SyncMsg<M> sr, SyncInfo si);
	Future<void> clear();
	Future<SyncMsg<M>> loadAll();
}

class NullDatabase<M extends IJSON> extends EventDatabase<M> {

	SyncInfo _lastSave = SyncInfo.zero();
	@override
	Future<void> add(SyncMsg<M> sr, SyncInfo si) async {
		_lastSave = si;
	}
	@override
	Future<void> clear() async {}
	@override
	SyncInfo lastSaved() => _lastSave;
	@override
	Future<SyncMsg<M>> loadAll() => Future.value(SyncMsg([], []));
}
