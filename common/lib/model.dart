library common;

import 'package:common/Event.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:json_annotation/json_annotation.dart';
import 'AbstractEventModel.dart';
import 'util.dart';

part "model.g.dart";

@JsonSerializable()
class Loop extends IJSON {
	int distance;
	Loop(this.distance);
	JSON toJson() => _$LoopToJson(this);
	factory Loop.fromJson(JSON json) =>
		_$LoopFromJson(json);
}

@JsonSerializable()
class Category extends IJSON {
	String name;
	List<Loop> loops;
	@JsonKey(ignore: false)
	List<Equipage> equipages;
	Category(this.name, this.loops) :
		equipages = [];

	int numDNF() =>
		equipages.where((e) => e.isOut).length;

	int numFinished() =>
		equipages.where((e) => e.isFinished).length;

	int numEnded() =>
		equipages.where((e) => e.isEnded).length;

	bool get isEnded => numEnded() == equipages.length;

	int distance() {
		int dist = 0;
		for (var l in loops)
			dist += l.distance;
		return dist;
	}

	JSON toJson() => _$CategoryToJson(this);
	factory Category.fromJson(JSON json) =>
		_$CategoryFromJson(json);
	
}

/* // todo: not unique id
@JsonSerializable()
class EventId extends IJSON {

	EventId(this.time, this.author);

	final int time;
	final String author;

	JSON toJson() => _$EventIdFromJson(this);
	factory EventId.fromJson(JSON json) =>
		_$EventIdFromJson(json);

} */

// todo: make enum of errors
@JsonSerializable()
class EventError extends IJSON {

   EventError(this.description, this.causedBy);

   String description;
   @JsonKey(fromJson: eventFromJSON)
   Event<Model> causedBy;

	JSON toJson() => _$EventErrorToJson(this);
	factory EventError.fromJson(JSON json) =>
		_$EventErrorFromJson(json);

}

class Model extends IJSON {

	String rideName = "";
	Map<String, Category> categories = {};
	Map<int, Equipage> equipages = {};
	List<EventError> errors = [];
	List<EventError> warnings = [];
			
	List<Equipage> vetGate() {
		List<Equipage> eqs = [];
		for (Equipage e in equipages.values) {
			if (e.loops.length == 0)
				continue;
			if (e.loops.last.vet == null && e.loops.last.arrival != null)
				eqs.add(e);
		}
		return eqs;
	}

	List<Equipage> examGate() {
		List<Equipage> eqs = [];
		for (Equipage e in equipages.values) {
			if (e.preExam == null) {
				eqs.add(e);
				continue;
			}
			if (e.loops.length == 0)
				continue;
			if (e.loops.last.vet != null && e.loops.last.data == null)
				eqs.add(e);
		}
		return eqs;
	}

	Model();
	Model.fromJson(JSON json) {
		JSON c0 = json["categories"];
		Map<String, Category> c1 = c0.map((key, value) => MapEntry(key,Category.fromJson(value)));
		JSON e0 = json["equipages"];
		Map<int, Equipage> e1 = e0.map((key, value) => MapEntry(int.parse(key),Equipage.fromJson(value, c1)));
		categories = c1;
		equipages = e1;
		rideName = json["rideName"];
	}

	JSON toJson() => {
		"categories": categories.map((key, value)
			=> MapEntry(key, value.toJson())),
		"equipages": equipages.map((key, value)
			=> MapEntry(key.toString(), value.toJson())),
		"rideName": rideName,
	};

}

class Equipage extends IJSON {
	
	EquipageStatus status = EquipageStatus.WAITING;
	int eid;
	String rider;
	String horse;
	late Category category;
	VetData? preExam;
	List<LoopData> loops = [];
	int? currentLoop;
	String? dsqReason;

	Equipage(this.eid, this.rider,this.horse,this.category);

	LoopData? get currentLoopData =>
		currentLoop == null ? null : loops[currentLoop!];

	/// indicates this equipage failed to complete competition
	bool get isOut =>
		status == EquipageStatus.DNF || status == EquipageStatus.RETIRED;
	
	/// indicates this equipage successfully completed competition
	bool get isFinished =>
		status == EquipageStatus.FINISHED;
		
	/// indicates this equipage no longer competing
	bool get isEnded =>
		status == EquipageStatus.DNF ||
		status == EquipageStatus.FINISHED ||
		status == EquipageStatus.RETIRED;

	double? averageSpeed() {
		if (loops.isEmpty)
			return null;
		double time = 0;
		double dist = 0;
		for (int i = 0; i < loops.length - 1; i++) {
			var t = loops[i].timeToVet;
			if (t == null)
				continue;
			time += t;
			dist += category.loops[i].distance;
		}
		var t = loops.last.timeToArrival;
		if (t != null) {
			time += t;
			dist += category.loops.last.distance;
		}
		if (time == 0) return null;
		return dist * 3600 / time;
	}

	static int byClassAndEid(Equipage a, Equipage b)
		=> a.compareClassAndEid(b);
	int compareClassAndEid(Equipage eq) {
		int c = eq.category.distance() - category.distance();
		return c != 0 ? c : compareEid(eq);
	}

	static int byEid(Equipage a, Equipage b)
		=> a.compareEid(b);
	int compareEid(Equipage eq)
		=> eid - eq.eid;

	static int byRank(Equipage a, Equipage b)
		=> a.compareRank(b);
	int compareRank(Equipage eq) {
		assert(category == eq.category, "Tried to compare rank across categories");

		// check for dnf
		if (isOut != eq.isOut) {
			if (isOut) return 1;
			else return -1;
		}

		if (currentLoop != eq.currentLoop)
			// largest loop
			return (eq.currentLoop ?? -1) - (currentLoop ?? -1);
		if (currentLoop == null)
			// before preExam, smallest eid
			return eid - eq.eid;
		var l = loops[currentLoop!];
		var eql = eq.loops[currentLoop!];
		if (l.vet != eql.vet && currentLoop! != eq.loops.length)
			// first vet time, unless final loop
			return (l.vet ?? UNIX_FUTURE) - (eql.vet ?? UNIX_FUTURE);
		if (l.arrival != eql.arrival)
			// first arrival time
			return (l.arrival ?? UNIX_FUTURE) - (eql.arrival ?? UNIX_FUTURE);
		if (l.expDeparture != eql.expDeparture)
			// first expected departure
			return (l.expDeparture ?? UNIX_FUTURE) - (eql.expDeparture ?? UNIX_FUTURE);
		
		// smallest eid
		return eid - eq.eid;
	}

	void updateStatus() {
		if (currentLoop == null) {
			if (preExam == null) {
				// ommitted to allow manual WAITING -> VET transition
				// status = EquipageStatus.VET;
			} else {
				if (!preExam!.passed)
					status = EquipageStatus.DNF;
				else
					status = EquipageStatus.RESTING;
			}
		} else {
			var l = loops[currentLoop!];
			if (l.data != null) {
				if (!l.data!.passed)
					status = EquipageStatus.DNF;
				else if (l == loops.last)
					status = EquipageStatus.FINISHED;
				else
					status = EquipageStatus.RESTING;
			}
			else if (l.vet != null)
				status = EquipageStatus.VET;
			else if (l.arrival != null)
				status = EquipageStatus.COOLING;
			else if (l.departure != null)
				status = EquipageStatus.RIDING;
			else
				status = EquipageStatus.RESTING;
		}
	}
	
	Equipage.fromJson(JSON json, Map<String, Category> catMap) :
		status = EquipageStatus.fromJson(json["status"]),
		eid = json["eid"],
		rider = json["rider"],
		horse = json["horse"],
		currentLoop = json["currentLoop"],
		dsqReason = json["dsqReason"] {
			category = catMap[json["category"]]!;
			category.equipages.add(this);
			preExam = jmap(json, "preExam", VetData.fromJson);
			loops = jlist_map(json["loops"], LoopData.fromJson);
			for (int i = 0; i < loops.length; i++)
				loops[i].loop = category.loops[i];
		}

	JSON toJson() => {
		"status": status.name,
		"eid": eid,
		"rider": rider,
		"horse": horse,
		"dsqReason": dsqReason,
		"category": category.name,
		"preExam": preExam?.toJson(),
		"loops": listj(loops),
		"currentLoop": currentLoop,
	};

	String toString() {
		return "${category.name} $eid $rider";
	}

}

@JsonSerializable()
class LoopData extends IJSON {
	@JsonKey(ignore: false)
	late Loop loop;
	int? expDeparture;
	int? departure;
	int? arrival;
	int? vet;
	VetData? data;

	double? speed({bool finish = false}) {
		int? t = finish ? timeToArrival : timeToVet;
		if (t == null) return null;
		return loop.distance * 3600 / t;
	}

	int? get recoveryTime =>
		arrival != null && vet != null ? vet! - arrival! : null;

	int? get timeToVet =>
		expDeparture != null && vet != null ? vet! - expDeparture! : null;
		
	int? get timeToArrival =>
		expDeparture != null && arrival != null ? arrival! - expDeparture! : null;
	
	/** does NOT initialize `loop` field */
	LoopData();
	LoopData.withLoop(this.loop);
	JSON toJson() => _$LoopDataToJson(this);
	factory LoopData.fromJson(JSON json) =>
		_$LoopDataFromJson(json);

}

enum EquipageStatus {
	WAITING,
	RIDING,
	VET,
	DNF,
	FINISHED,
	COOLING,
	RESTING,
	RETIRED;

	String toJson() => name;
	factory EquipageStatus.fromJson(dynamic status) =>
		EquipageStatus.values.byName(status as String);

}

@JsonSerializable()
class VetData extends IJSON {

	bool passed;
	int? hr1, hr2, resp, mucMem, cap, jug, hydr, gut, sore, wounds, gait, attitude;
	VetData(this.passed);

	VetData.empty() : this.passed = false;
	VetData.passed() : this.passed = true;

	VetData clone() => VetData.fromJson(toJson());

	JSON toJson() => _$VetDataToJson(this);
	factory VetData.fromJson(JSON json) =>
		_$VetDataFromJson(json);

}
