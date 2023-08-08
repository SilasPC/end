
import 'package:common/EnduranceEvent.dart';

import 'AbstractEventModel.dart';
import 'util.dart';

class SyncRequest<M extends IJSON> extends IJSON {
	/** Deletes to be pushed */
	final List<EventId> deletes;
	/** Events to be pushed */
	final List<Event<M>> events;
	/** The current local generation */
	final int newGen;
	/** Info about last sync */
	final SyncInfo lastSync;
	SyncRequest(this.lastSync, this.newGen, this.events, this.deletes);
	
	@override
	JSON toJson() => {
		"events": listj(events),
		"deletes": listj(deletes),
		"newGen": newGen,
		"lastSync": lastSync.toJson(),
	};

	SyncRequest.fromJSON(JSON json) :
		deletes = jlist_map(json["deletes"], EventId.fromJson),
		events = jlist_map(json["events"], eventFromJSON as Reviver<Event<M>>),
		newGen = json["newGen"],
		lastSync = SyncInfo.fromJson(json["lastSync"]);
		
}

// sync to a remote model
abstract class AbstractEventModelWithRemoteSync<M extends IJSON> extends AbstractEventModel<M> {

	AbstractEventModelWithRemoteSync(M model, List<Event<M>> events) :
		super(model, events);

	Future<SyncResult<M>> $doRemoteSync(SyncRequest<M> req);

	SyncInfo lastSync = SyncInfo.zero();
	List<Event<M>> _unsyncedEvents = [];
	List<EventId> _unsyncedDeletes = [];

	Future<void> syncRemote() async {
		SyncRequest<M> ra = SyncRequest(lastSync, gen, _unsyncedEvents, _unsyncedDeletes);
		_unsyncedEvents = [];
		_unsyncedDeletes = [];
		try {
			SyncResult<M> res = await $doRemoteSync(ra);
			model = res.model ?? model;
			// find and replace
			if (res.events.isNotEmpty) {
				_replaceEvents(res.events);
			}
			if (gen < res.newGen) {
				gen = res.newGen;
			}
			lastSync = SyncInfo(gen, events.length, deletes.length);
			$onUpdate();
		} catch (e) {
			_unsyncedEvents = ra.events..addAll(_unsyncedEvents);
			_unsyncedDeletes = ra.deletes..addAll(_unsyncedDeletes);
			restoreFromLatestSavepoint(); // in case of corruption
			rethrow;
		}
	}

	/**
	 * Replace the tail with the events `evs`.
	 * Example pre:
	 * 	`evs`		=    DEFGH
	 * 	`events`	= ABC---GH
	 * Example post:
	 * 	`events`	= ABCDEFGH
	 * The index of D is returned.
	 */
	int _replaceEvents(List<Event<M>> evs) {
		// replace all elements after evs.first
		int i = binarySearch(events, (e) => e.time >= evs.first.time);
		if (i != -1) {
			events.removeRange(i, events.length);
		}
		events.addAll(evs);
		return i;
	}

	void addNoSync(List<Event<M>> evs) {
		_unsyncedEvents.addAll(evs);
		addEvents(evs);
	}

	Future<void> appendAndSync(List<Event<M>> evs, List<EventId> dlts) async {
		_unsyncedEvents.addAll(evs);
		_unsyncedDeletes.addAll(dlts);
		append(evs, dlts);
		return syncRemote();
	}

	Future<void> addAndSync(List<Event<M>> evs) async {
		_unsyncedEvents.addAll(evs);
		addEvents(evs);
		return syncRemote();
	}

	Future<void> resetAndSync() async {
		_unsyncedEvents.clear();
		events.clear();
		gen = 0;
		lastSync = SyncInfo.zero();
		savepoints.removeRange(1, savepoints.length);
		restoreFromLatestSavepoint();
		return syncRemote();
	}

}
