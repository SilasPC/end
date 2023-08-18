
import '../EnduranceEvent.dart';
import '../util.dart';
import 'EventModel.dart';

class SyncedEventModel<M extends IJSON> extends EventModel<M> {

	final Future<SyncResult<M>> Function(SyncRequest<M>) _syncFunc;

	SyncInfo _lastSyncRemote = SyncInfo.zero();
	SyncInfo _lastSyncLocal = SyncInfo.zero();

	SyncedEventModel(super.handle, this._syncFunc);

	Future<void> sync() =>_syncFut = _syncFut.then((_) => _sync());
	Future<void> _syncFut = Future((){});
	Future<void> _sync() async {
		var data = getNewerData(_lastSyncLocal);
		var res = await _syncFunc(SyncRequest(_lastSyncRemote, data.events, data.deletes));
		add(res.events, res.deletes);
		_lastSyncRemote = res.syncInfo;
		_lastSyncLocal = syncState;
	}

	Future<void> addSync(List<Event<M>> newEvents, [List<Event<M>> newDeletes = const []]) {
		add(newEvents, newDeletes);
		return sync();
	}

}

class SyncRequest<M extends IJSON> extends IJSON {
	final List<Event<M>> events;
	final List<Event<M>> deletes;
	final SyncInfo lastSync;

	SyncRequest(this.lastSync, this.events, this.deletes);

	SyncResult<M> applyTo(EventModel<M> em) {
		em.add(events, deletes);
		return em.getNewerData(lastSync);
	}
	
	@override
	JSON toJson() => {
		"events": listj(events),
		"deletes": listj(deletes),
		"lastSync": lastSync.toJson(),
	};

	SyncRequest.fromJSON(JSON json) :
		deletes = jlist_map(json["deletes"], eventFromJSON as Reviver<Event<M>>),
		events = jlist_map(json["events"], eventFromJSON as Reviver<Event<M>>),
		lastSync = SyncInfo.fromJson(json["lastSync"]);
		
}
