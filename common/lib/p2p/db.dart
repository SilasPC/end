
import 'package:common/p2p/Manager.dart';

import '../event_model/EventModel.dart';

abstract class EventDatabase {
	SyncInfo lastSaved();
	Future<void> add(Msg sr, SyncInfo si);
	Future<void> clear();
	Future<Msg> loadAll();
}

class NullDatabase extends EventDatabase {

	static NullDatabase create() => NullDatabase();

	SyncInfo _lastSave = SyncInfo.zero();
	@override
	Future<void> add(Msg sr, SyncInfo si) async {
		_lastSave = si;
	}
	@override
	Future<void> clear() async {}
	@override
	SyncInfo lastSaved() => _lastSave;
	@override
	Future<Msg> loadAll() => Future.value(Msg([], []));
}
