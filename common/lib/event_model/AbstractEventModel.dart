
import 'dart:convert';
import 'dart:math';
import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:json_annotation/json_annotation.dart';
import '../EnduranceEvent.dart';
import 'Event.dart';
import '../util.dart';

part "AbstractEventModel.g.dart";

class SyncPush<M extends IJSON> extends IJSON {
	final int gen;
	final List<Event<M>> events;
	SyncPush(this.gen, this.events);
	JSON toJson() => {
		"gen": gen,
		"events": listj(events),
	};
	SyncPush.fromJson(JSON json) :
		gen = json["gen"],
		events = jlist_map(json["events"], eventFromJSON as Reviver<Event<M>>);
}

@JsonSerializable()
class SyncInfo extends IJSON {

	final int gen;
	final int evLen;
	final int delLen;
	SyncInfo(this.gen, this.evLen, this.delLen);

	factory SyncInfo.zero() => SyncInfo(0, 0, 0);

	JSON toJson() => _$SyncInfoToJson(this);
	factory SyncInfo.fromJson(JSON json)
		=> _$SyncInfoFromJson(json);
}

class Savepoint<M extends IJSON> {
	final SyncInfo si;
	final String json;
	final int newestEventTime;
	Savepoint(this.si, this.newestEventTime, M model) :
		json = model.toJsonString();
}

class SyncResult<M extends IJSON> extends IJSON {
	/** The model as seen right after `events` took place */
	final M? model;
	/** All events after this first must be replaced */
	final List<Event<M>> events;
	final List<EventId> deletes;

	/** The new generation number */
	final int newGen;
	SyncResult(this.model,this.events,this.deletes,this.newGen);

	factory SyncResult.empty(int gen) => SyncResult(null, [], [], gen);

	JSON toJson() => {
		"model": model?.toJson(),
		"events": listj(events),
		"deletes": listj(deletes),
		"newGen": newGen,
	};

	SyncResult.fromJSON(JSON json, Reviver<M> reviver) :
		model = jmap(json, "model", reviver),
		events = jlist_map(json["events"], eventFromJSON as Reviver<Event<M>>),
		deletes = jlist_map(json["deletes"], EventId.fromJson),
		newGen = json["newGen"];

}

abstract class AbstractEventModel<M extends IJSON> {

	M model;
	List<Event<M>> events;
	Set<EventId> deletes;
	List<Savepoint<M>> savepoints;
	int gen = 0;

	M $reviveModel(JSON json);
	void $onUpdate();

	AbstractEventModel(this.model, this.events) :
		deletes = Set(),
		savepoints = [Savepoint(SyncInfo.zero(), 0, model)] {
			unsafeBuildFromIndex(0);
		}
	
	AbstractEventModel.withBase(this.model) :
		deletes = Set(),
		events = [],
		savepoints = [Savepoint(SyncInfo.zero(), 0, model)];


	void createSavepoint() {
		savepoints.add(Savepoint(
			SyncInfo(gen, events.length, deletes.length),
			events.last.time,
			model
		));
	}

	void acceptPush(SyncPush<M> sp) {
		addEvents(sp.events);
		if (gen < sp.gen) gen = sp.gen;
	}

	/** should not be used through local model */
	void addEvents(List<Event<M>> evs) {
		append(evs, []);
	}

	SyncResult<M> syncFromRequest(SyncRequest<M> sr) {

		bool newDataAvailable =
			events.length > sr.lastSync.evLen ||
			deletes.length > sr.lastSync.delLen;

		append(sr.events, sr.deletes);
		if (newDataAvailable)
			return backSync(sr.lastSync);
		return SyncResult(null, [], [], gen);
	}

	void append(List<Event<M>> es, [List<EventId> dlts = const []]) {

		if (es.isEmpty && dlts.isEmpty) return;
		
		int? revertTo;

		if (dlts.isNotEmpty) {
			dlts.sort();
			revertTo = dlts.first.time;
			deletes.addAll(dlts);
		}

		if (es.isNotEmpty) {
			es.sort();
			int minTime = es[0].time;
			int? maxOldTime = events.isNotEmpty ? events.last.time : null;
			events.addAll(es);

			if (maxOldTime != null && maxOldTime > minTime) {
				print("  insert ($minTime < $maxOldTime)");
				events.sort();
				revertTo = revertTo == null ? minTime : min(revertTo, minTime);
			}
		}

		if (revertTo != null) {
			// kill all savepoints with newestEvent >= minTime
			killSavepointsAfter(revertTo);
			restoreFromLatestSavepoint();
		} else {
			// all events in order, build appended
			unsafeBuildFromIndex(events.length - es.length);
		}

		gen++;

		$onUpdate();

	}

	SyncResult<M> backSync(SyncInfo lastSync) {
		// find savepoint sp with sp.si.gen < lastSync.gen
		// send sp.model, events.sublist(sp.si.evLen+1), new gen
		int i = binarySearchLast(savepoints, (sp) => sp.si.gen <= lastSync.gen);
		Savepoint<M> sp = savepoints[i];
		print("  backsync ${sp.newestEventTime}");
		var newEvents = events.sublist(sp.si.evLen);
		var newDeletes = deletes.toList(); // todo: don't send all deletes every time
		return SyncResult(cloneModel(), newEvents, newDeletes, gen);
	}

	void killSavepointsAfter(int t) {
		int i = binarySearchLast(savepoints, (sp) => sp.newestEventTime < t);
		savepoints.removeRange(i + 1, savepoints.length);
	}

	void restoreFromLatestSavepoint() {
		Savepoint<M> sp = savepoints.last;
		print("restore ${sp.newestEventTime}");
		model = $reviveModel(jsonDecode(sp.json));
		unsafeBuildFromIndex(sp.si.evLen);
	}

	void unsafeBuildFromIndex(int i) {
		for (; i < events.length; i++) {
			var ev = events[i];
			if (deletes.contains(EventId.of(ev))) continue;
			if (!events[i].build(this)) {
				print("build ${events[i].toJson()} failed");
			}
			/* try {
			} catch (e) {
				print("build ${events[i].toJson()} exception: $e");
			} */
		}
	}

	M cloneModel() => $reviveModel(jsonDecode(model.toJsonString()));

}
