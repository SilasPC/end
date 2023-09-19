
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
	final int? lastInsIndex;
	final int? lastTime;
	final SyncInfo si;
	final String json;
	Savepoint(this.si, M model, this.lastInsIndex, this.lastTime) :
		json = model.toJsonString();

	String toString() => "SP ${si.toJsonString()} $json";
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
	final int _savepointInterval;
	int? _maxBuildTime;

   int _buildIndex = -1;
   int get buildIndex => _buildIndex;

	EventModel(this._handle, [this._savepointInterval = 1000]) {
		_handle.model = this;
		model = _handle.createModel();
		createSavepoint();
	}

	void createSavepoint() {
		int? lastEventTime = events.isEmpty ? null : events.last.time;
		savepoints.add(Savepoint(
			SyncInfo(events.length, deletes.length),
			model,
			events.lastInsertionIndex,
			lastEventTime,
		));
	}

	void setMaxTime(int? maxTime) {
		if (maxTime == _maxBuildTime) return;
		if (_maxBuildTime != null && (maxTime == null || maxTime > _maxBuildTime!)) {
			// delete constraint
			int buildFrom = events.binarySearch((e) => e.time > _maxBuildTime!);
			_maxBuildTime = maxTime;
			if (buildFrom != -1) {
				_handle.willUpdate();
				_buildFromIndex(buildFrom);
				_handle.didUpdate();
			}
		} else if (maxTime != null && (_maxBuildTime == null || _maxBuildTime! > maxTime)) {
			// add constraint
			_maxBuildTime = maxTime;
			_handle.willUpdate();
			_restoreFromSavepoint();
			_handle.didUpdate();
		}
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
			_restoreFromSavepoint();
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
		int i = binarySearchLast(savepoints, (sp) => sp.si.evLen <= evLen);
		savepoints.removeRange(i + 1, savepoints.length);
	}

	void _restoreFromSavepoint() {
		Savepoint<M> sp;
		if (_maxBuildTime != null) {
			sp = savepoints.lastWhere((sp) => sp.lastTime == null || sp.lastTime! <= _maxBuildTime!);
		} else {
			sp = savepoints.last;
		}
		int i = 0;
		if (sp.si.evLen > 0) {
			i = events.toOrdIndex(sp.lastInsIndex!)! + 1;
			model = _handle.revive(jsonDecode(sp.json));
		} else {
			model = _handle.createModel();
		}
		_buildFromIndex(i);
	}

	void _buildFromIndex(int i) {
		var it = events.iterator.skip(i);
		if (_maxBuildTime != null) {
			var max = _maxBuildTime!;
			it = it.takeWhile((ev) => ev.time <= max);
		}
      _buildIndex = i;
		for (var ev in it) {
			if (!deletes.contains(ev)) {
            ev.build(this);
			}
			if (savepoints.last.si.evLen < _buildIndex - _savepointInterval) {
				createSavepoint();
			}
         _buildIndex++;
		}
      _buildIndex = -1;
	}

}
