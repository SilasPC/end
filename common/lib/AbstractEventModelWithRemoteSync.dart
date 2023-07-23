
import 'package:common/Event.dart';

import 'AbstractEventModel.dart';
import 'util.dart';

class SyncRequest extends IJSON {
	/** Events to be pushed */
	final List<Event> events;
	/** The current local generation */
	final int newGen;
	/** Info about last sync */
	final SyncInfo lastSync;
	SyncRequest(this.lastSync, this.newGen, this.events);
	
	@override
	Map<String, dynamic> toJson() => {
		"events": listj(events),
		"newGen": newGen,
		"lastSync": lastSync.toJson(),
	};

	SyncRequest.fromJSON(Map<String, dynamic> json) :
		events = jlist_map(json["events"], eventFromJSON),
		newGen = json["newGen"],
		lastSync = SyncInfo.fromJSON(json["lastSync"]);
		
}

// sync to a remote model
abstract class AbstractEventModelWithRemoteSync<M extends IJSON> extends AbstractEventModel<M> {

	AbstractEventModelWithRemoteSync(M model, List<Event> events) :
		super(model, events);

	AbstractEventModelWithRemoteSync._withBase(super.model) : super.withBase();

	Future<SyncResult<M>> $doRemoteSync(SyncRequest req);

	SyncInfo lastSync = SyncInfo(0, 0);
	List<Event> _unsyncedEvents = [];

	Future<void> syncRemote() async {
		SyncRequest ra = SyncRequest(lastSync, gen, _unsyncedEvents);
		_unsyncedEvents = [];
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
			lastSync = SyncInfo(gen, events.length);
			$onUpdate();
		} catch (e) {
			_unsyncedEvents = ra.events..addAll(_unsyncedEvents);
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
	int _replaceEvents(List<Event> evs) {
		// replace all elements after evs.first
		int i = binarySearch(events, (e) => e.time >= evs.first.time);
		if (i != -1) {
			events.removeRange(i, events.length);
		}
		events.addAll(evs);
		return i;
	}

	void addNoSync(List<Event> evs) {
		_unsyncedEvents.addAll(evs);
		addEvents(evs);
	}

	Future<void> addAndSync(List<Event> evs) async {
		_unsyncedEvents.addAll(evs);
		addEvents(evs);
		return syncRemote();
	}

}
