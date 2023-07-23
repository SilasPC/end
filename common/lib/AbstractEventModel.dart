
import 'dart:convert';

import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:common/Event.dart';

import 'util.dart';

abstract class Event<M extends IJSON> extends IJSON implements Comparable<Event<M>> {
	final String kind;
	final int time;
	final String author;
	Event(this.time, this.kind, this.author);
	bool build(AbstractEventModel<M> m);

	int compareTo(Event<M> rhs) {
		int i = time - rhs.time;
		if (i == 0) i = kind.compareTo(rhs.kind);
		if (i == 0) i = author.compareTo(rhs.author);
		return i;
	}

}

class SyncPush extends IJSON {
	final int gen;
	final List<Event> events;
	SyncPush(this.gen, this.events);
	JSON toJson() => {
		"gen": gen,
		"events": listj(events),
	};
	SyncPush.fromJSON(JSON json) :
		gen = json["gen"],
		events = jlist_map(json["events"], eventFromJSON);
}

class SyncInfo extends IJSON {
	final int gen;
	final int evLen;
	SyncInfo(this.gen, this.evLen);

	JSON toJson() => {
		"gen": gen,
		"evLen": evLen,
	};

	SyncInfo.fromJSON(JSON json) :
		gen = json["gen"],
		evLen = json["evLen"];
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
	final List<Event> events;
	/** The new generation number */
	final int newGen;
	SyncResult(this.model,this.events,this.newGen);

	factory SyncResult.empty(int gen) => SyncResult(null, [], gen);

	JSON toJson() => {
		"model": model?.toJson(),
		"events": listj(events),
		"newGen": newGen,
	};

	SyncResult.fromJSON(JSON json, M Function(JSON model) reviver) :
		model = jmap(json, "model", reviver),
		events = jlist_map(json["events"], eventFromJSON),
		newGen = json["newGen"];

}

abstract class AbstractEventModel<M extends IJSON> {

	M model;
	List<Event> events;
	List<Savepoint<M>> savepoints;
	int gen = 0;

	M $reviveModel(JSON json);
	void $onUpdate();

	AbstractEventModel(this.model, this.events) :
		savepoints = [Savepoint(SyncInfo(0, 0), 0, model)] {
			unsafeBuildFromIndex(0);
		}
	
	AbstractEventModel.withBase(this.model) :
		events = [],
		savepoints = [Savepoint(SyncInfo(0, 0), 0, model)];


	void createSavepoint() {
		savepoints.add(Savepoint(
			SyncInfo(gen, events.length),
			events.last.time,
			model
		));
	}

	void acceptPush(SyncPush sp) {
		addEvents(sp.events);
		if (gen < sp.gen) gen = sp.gen;
	}

	/** should not be used through local model */
	void addEvents(List<Event> evs) {
		sync(evs, SyncInfo(gen, evs.length), gen+1);
	}

	SyncResult<M> syncFromRequest(SyncRequest sr) => sync(sr.events, sr.lastSync, sr.newGen);
	SyncResult<M> sync(List<Event> es, SyncInfo lastSync, int newGen) {

		if (!es.isEmpty) {
			es.sort();
			int i = events.length;
			int minTime = es[0].time;
			int? maxOldTime = events.isNotEmpty ? events.last.time : null;
			events.addAll(es);

			if (maxOldTime != null && maxOldTime > minTime) {
				print("  insert ($minTime < $maxOldTime)");
				events.sort();

				// kill all savepoints with newestEvent >= minTime
				killSavepointsAfter(minTime);
				restoreFromLatestSavepoint();

			} else {
				// all events in order
				unsafeBuildFromIndex(i);
			}

			gen = newGen > gen + 1 ? newGen : gen + 1;

			$onUpdate();
		}

		if (events.length > lastSync.evLen + es.length) {
			// other events added since lastSync
			// find savepoint sp with sp.si.gen < lastSync.gen
			// send sp.model, events.sublist(sp.si.evLen+1), new gen
			// todo: binary search
			Savepoint<M> sp = savepoints.lastWhere((sp) => sp.si.gen <= lastSync.gen);
			print("  backsync ${sp.newestEventTime}");
			return SyncResult(cloneModel(), events.sublist(sp.si.evLen), gen);
		} else {
			// no other events added since
			// send aknowledgement
			assert(gen == lastSync.gen + 1);
			return SyncResult(cloneModel(), [], gen);
		}

	}

	void killSavepointsAfter(int t) {
		for (int i = savepoints.length - 1; i >= 0; i--) {
			// todo: binary search
			if (savepoints[i].newestEventTime < t) {
				savepoints.removeRange(i + 1, savepoints.length);
				break;
			}
		}
	}

	void restoreFromLatestSavepoint() {
		Savepoint<M> sp = savepoints.last;
		print("restore ${sp.newestEventTime}");
		model = $reviveModel(jsonDecode(sp.json));
		unsafeBuildFromIndex(sp.si.evLen);
	}

	void unsafeBuildFromIndex(int i) {
		for (; i < events.length; i++) {
			try {
				if (!events[i].build(this))
					print("build ${events[i].toJson()} failed");
			} catch (e) {
				print("build ${events[i].toJson()} exception: $e");
			}
		}
	}

	M cloneModel() => $reviveModel(jsonDecode(model.toJsonString()));

}
