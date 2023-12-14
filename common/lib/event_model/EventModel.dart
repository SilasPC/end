
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:common/event_model/OrderedSet.dart';
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

abstract class EventModelHandle<M extends IJSON> {
	late EventModel<M> model;
	M revive(JSON json);
	Event<M> reviveEvent(JSON json);
	M createModel();
	void willUpdate() {}
	void didUpdate() {}
	void didReset() {}
}

class EventModel<M extends IJSON> {

	final EventModelHandle<M> _handle;

	late M model;
	final OrderedSet<Event<M>> _events = OrderedSet();
	final LinkedHashSet<Event<M>> deletes = LinkedHashSet();
	final List<Savepoint<M>> savepoints = [];
	final int _savepointInterval;
	int? _maxBuildTime;

	ReadOnlyOrderedSet<Event<M>> get events => _events;

   int _buildIndex = -1;
   int get buildIndex => _buildIndex;

	EventModel(this._handle, [this._savepointInterval = 1000]) {
		_handle.model = this;
		model = _handle.createModel();
		createSavepoint();
	}

	void createSavepoint() {
		if (_maxBuildTime != null) return;
		int? lastEventTime = _events.isEmpty ? null : _events.last.time;
		savepoints.add(Savepoint(
			syncState,
			model,
			_events.lastInsertionIndex,
			lastEventTime,
		));
	}

	void setMaxTime(int? maxTime) {
		if (maxTime == _maxBuildTime) return;
		int? oldMaxTime = _maxBuildTime;
		_maxBuildTime = maxTime;

		void fastForward(int oldMaxTime) {
			int buildFrom = _events.binarySearch((e) => e.time > oldMaxTime);
			if (buildFrom != -1) {
				_handle.willUpdate();
				_buildFromIndex(buildFrom);
				_handle.didUpdate();
			}
		}

		switch ((oldMaxTime, maxTime)) {
			case (int oldMaxTime, null):
				fastForward(oldMaxTime);
				break;
			case (int oldMaxTime, int maxTime) when maxTime > oldMaxTime:
				fastForward(oldMaxTime);
				break;
			case (null, int _):
			case (int oldMaxTime, int maxTime) when maxTime < oldMaxTime:
				// rollback
				_handle.willUpdate();
				_restoreFromSavepoint();
				_handle.didUpdate();
				break;
		}

	}

	void reset() {
		model = _handle.createModel();
		_events.clear();
		deletes.clear();
		savepoints.clear();
		createSavepoint();
		_handle.didReset();
	}

	void add(List<Event<M>> newEvents, [List<Event<M>> newDeletes = const []]) {

		if (newEvents.isEmpty && newDeletes.isEmpty) return;
		
		_handle.willUpdate();

		final int oldLength = _events.length;
		int buildFrom = _events.length + newEvents.length;

		if (newDeletes.isNotEmpty) {
			newDeletes.sort();
			deletes.addAll(newDeletes);
			buildFrom = _events.findOrdIndex(newDeletes.first) ?? buildFrom;
		}

		if (newEvents.isNotEmpty) {
			newEvents.sort();
			_events.addAll(newEvents);
			int? i = _events.findOrdIndex(newEvents.first);
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

	(List<Event<M>>, List<Event<M>>) getNewer(SyncInfo lastSync) {
		var evs = _events.iteratorInsertion.skip(lastSync.evLen).toList();
		var dls = deletes.skip(lastSync.delLen).toList();
		return (evs, dls);
	}

	SyncInfo get syncState => SyncInfo(_events.length, deletes.length);

	void _killSavepointsAfter(int evLen) {
		int i = binarySearchLast(savepoints, (sp) => sp.si.evLen <= evLen);
		savepoints.removeRange(i + 1, savepoints.length);
	}

	void _restoreFromSavepoint() {
		Savepoint<M> sp;
		if (_maxBuildTime case int maxTime) {
			sp = savepoints.lastWhere((sp) => sp.lastTime == null || sp.lastTime! <= maxTime);
		} else {
			sp = savepoints.last;
		}
		int i = 0;
		if (sp.si.evLen > 0) {
			i = _events.toOrdIndex(sp.lastInsIndex!)! + 1;
			model = _handle.revive(jsonDecode(sp.json));
		} else {
			model = _handle.createModel();
		}
		_buildFromIndex(i);
	}

	void _buildFromIndex(int i) {
		var it = _events.iterator.skip(i);
		if (_maxBuildTime case int maxTime) {
			it = it.takeWhile((ev) => ev.time <= maxTime);
		}
      _buildIndex = i;
		for (var ev in it) {
			if (!deletes.contains(ev)) {
            try {
               ev.build(this);
            } catch (_) {}
			}
			if (savepoints.last.si.evLen < _buildIndex - _savepointInterval) {
				createSavepoint();
			}
         _buildIndex++;
		}
      _buildIndex = -1;
	}

}
