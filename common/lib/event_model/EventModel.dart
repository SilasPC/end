
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:common/event_model/OrderedSet.dart';
import '../EnduranceEvent.dart';
import '../util.dart';
import 'Event.dart';

class SyncInfo extends IJSON {

	final int evLen;
	final int delLen;
	SyncInfo(this.evLen, this.delLen);

	factory SyncInfo.zero() => SyncInfo(0, 0);

	JSON toJson() => {
		"evLen": evLen,
		"delLen": delLen,
	};
	factory SyncInfo.fromJson(JSON json)
		=> SyncInfo(json["evLen"], json["delLen"]);

	bool operator ==(rhs) {
		if (rhs is SyncInfo) {
			return delLen == rhs.delLen && evLen == rhs.evLen;
		}
		return false;
	}

}

class Savepoint<M extends IJSON> {
	final SyncInfo si;
	final String json;
	Savepoint(this.si, M model) :
		json = model.toJsonString();
}

class SyncResult<M extends IJSON> extends IJSON {
	final List<Event<M>> events;
	final List<Event<M>> deletes;
	final SyncInfo syncInfo;
	SyncResult(this.events, this.deletes, this.syncInfo);

	factory SyncResult.empty() => SyncResult([], [], SyncInfo.zero());

	JSON toJson() => {
		"events": listj(events),
		"deletes": listj(deletes),
		"syncInfo": syncInfo,
	};

	SyncResult.fromJSON(JSON json) :
		syncInfo = SyncInfo.fromJson(json["syncInfo"]),
		events = jlist_map(json["events"], eventFromJSON as Reviver<Event<M>>),
		deletes = jlist_map(json["deletes"], eventFromJSON as Reviver<Event<M>>);

}

abstract class EventModelHandle<M extends IJSON> {
	late EventModel<M> model;
	M revive(JSON json);
	M createModel();
	void willUpdate() {}
	void didUpdate() {}
}

class EventModel<M extends IJSON> {

	final EventModelHandle<M> _handle;

	late M model;
	final OrderedSet<Event<M>> events = OrderedSet();
	final LinkedHashSet<Event<M>> deletes = LinkedHashSet();
	final List<Savepoint<M>> savepoints = [];

   int _buildIndex = -1;
   int get buildIndex => _buildIndex;

	EventModel(this._handle) {
		_handle.model = this;
		model = _handle.createModel();
		createSavepoint();
	}

	void createSavepoint() {
		savepoints.add(Savepoint(
			SyncInfo(events.length, deletes.length),
			model
		));
	}

	void reset() {
		model = _handle.createModel();
		events.clear();
		deletes.clear();
		savepoints.clear();
		createSavepoint();
	}

	void add(List<Event<M>> newEvents, [List<Event<M>> newDeletes = const []]) {

		if (newEvents.isEmpty && newDeletes.isEmpty) return;
		
		_handle.willUpdate();

		final int oldLength = events.length;
		int buildFrom = events.length + newEvents.length;

		if (newDeletes.isNotEmpty) {
			newDeletes.sort();
			deletes.addAll(newDeletes);
			buildFrom = events.findOrdIndex(newDeletes.first) ?? buildFrom;
		}

		if (newEvents.isNotEmpty) {
			newEvents.sort();
			events.addAll(newEvents);
			int? i = events.findOrdIndex(newEvents.first);
			buildFrom = min(i ?? buildFrom, buildFrom);
		}
		
		if (buildFrom < oldLength) {
			// restore from before buildFrom
			_killSavepointsAfter(buildFrom);
			_restoreFromLatestSavepoint();
		} else {
			// append only
			_buildFromIndex(buildFrom);
		}

		_handle.didUpdate();

	}

	SyncResult<M> getNewerData(SyncInfo lastSync) {
		var evs = events.iteratorInsertion.skip(lastSync.evLen).toList();
		var dls = deletes.skip(lastSync.delLen).toList();
		return SyncResult(evs, dls, syncState);
	}

	SyncInfo get syncState => SyncInfo(events.length, deletes.length);

	void _killSavepointsAfter(int evLen) {
		// TODO: binary search, correct <= ?
		int i = savepoints.lastIndexWhere((sp) => sp.si.evLen <= evLen);
		//int i = binarySearchLast(savepoints, (sp) => sp.si.evLen < evLen);
		savepoints.removeRange(i + 1, savepoints.length);
	}

	void _restoreFromLatestSavepoint() {
		Savepoint<M> sp = savepoints.last;
		int i = 0;
		if (sp.si.evLen > 0) {
			i = events.findOrdIndex(events.byInsertionIndex(sp.si.evLen - 1))!;
			model = _handle.revive(jsonDecode(sp.json));
		} else {
			model = _handle.createModel();
		}
		_buildFromIndex(i);
	}

	void _buildFromIndex(int i) {
		var it = events.iteratorOrdered.skip(i);
      _buildIndex = i;
		for (var ev in it) {
			if (!deletes.contains(ev)) {
            ev.build(this);
			}
         _buildIndex++;
		}
      _buildIndex = -1;
	}

}
