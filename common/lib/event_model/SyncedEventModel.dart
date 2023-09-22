
import '../EnduranceEvent.dart';
import '../EventModel.dart';
import '../util.dart';

class SyncedEventModel<M extends IJSON> extends EventModel<M> {

	final Future<SyncResult<M>> Function(SyncRequest<M>) _syncFunc;

	SyncInfo lastSyncRemote = SyncInfo.zero();
	SyncInfo lastSyncLocal = SyncInfo.zero();

	SyncedEventModel(super.handle, this._syncFunc);

	Future<void> sync() async {
		print("sync");
		var data = getNewerData(lastSyncLocal);
		var res = await _syncFunc(SyncRequest(lastSyncRemote, data.events, data.deletes));
		add(res.events, res.deletes);
		lastSyncRemote = res.syncInfo;
		lastSyncLocal = syncState;
	}

	Future<void> addSync(List<Event<M>> newEvents, [List<Event<M>> newDeletes = const []]) {
		add(newEvents, newDeletes);
		return sync();
	}

	void reset() {
		super.reset();
		lastSyncLocal = lastSyncRemote = SyncInfo.zero();
	}

	Future<void> resetSync() async {
		lastSyncLocal = lastSyncRemote = SyncInfo.zero();
		reset();
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

class SyncPush<M extends IJSON> extends IJSON {
	final List<Event<M>> events;
	final List<Event<M>> deletes;
	SyncPush(this.events, this.deletes);
	JSON toJson() => {
		"events": listj(events),
		"deletes": listj(deletes),
	};
	SyncPush.fromJson(JSON json) :
		events = jlist_map(json["events"], eventFromJSON as Reviver<Event<M>>),
		deletes = jlist_map(json["deletes"], eventFromJSON as Reviver<Event<M>>);
}
