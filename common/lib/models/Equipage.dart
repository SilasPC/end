
import 'package:json_annotation/json_annotation.dart';

import '../util.dart';
import 'glob.dart';

part "Equipage.g.dart";

enum EquipageStatus {
	WAITING,
	RIDING,
	VET,
	DNF,
	FINISHED,
	COOLING,
	RESTING,
	RETIRED;

	/// indicates equipage failed to complete competition
	bool get isOut =>
		this == EquipageStatus.DNF || this == EquipageStatus.RETIRED;

	/// indicates equipage successfully completed competition
	bool get isFinished =>
		this == EquipageStatus.FINISHED;

	/// indicates equipage no longer competing
	bool get isEnded =>
		this == EquipageStatus.DNF ||
		this == EquipageStatus.FINISHED ||
		this == EquipageStatus.RETIRED;

	String toJson() => name;
	factory EquipageStatus.fromJson(dynamic status) =>
		EquipageStatus.values.byName(status as String);

}

@JsonSerializable(constructor: "raw")
class Equipage extends IJSON {

	EquipageStatus status = EquipageStatus.WAITING;
	int eid;
	String rider;
	String horse;
	VetData? preExam;
	List<LoopData> loops = [];
	int? currentLoop;
	String? dsqReason;
	int startOffsetSecs = 0;

	@JsonKey(ignore: true)
	late Category _category;
	@JsonKey(ignore: true)
	Category get category => _category;
	set category(Category cat) {
		_category = cat;
		loops = cat.loops.map((l) => LoopData(l)).toList();
	}

	Equipage(this.eid, this.rider,this.horse, this._category);
	Equipage.raw(this.eid, this.rider,this.horse);

	bool skipLoop() {
		if (isFinalLoop) return false;
		if (currentLoop == null) return false;
		if (currentLoopData case LoopData ld) {
			if (ld.vet case int vet) {
				loops[currentLoop!+1].expDeparture = vet + ld.loop.restTime * 60;
			}
		}
		currentLoop = currentLoop! + 1;
		return true;
	}

	LoopData? get currentLoopData =>
		currentLoop == null ? null : loops[currentLoop!];

	LoopData? get previousLoopData =>
		currentLoop == null || currentLoop! - 1 < 0 ? null : loops[currentLoop! - 1];

	/// indicates this equipage failed to complete competition
	bool get isOut => status.isOut;
	/// indicates this equipage successfully completed competition
	bool get isFinished => status.isFinished;
	/// indicates this equipage no longer competing
	bool get isEnded => status.isEnded;

	/// indicates whether the equipage is on their final loop
	bool get isFinalLoop => currentLoop != null && currentLoop == category.loops.length - 1;

	/// returns the total ride time (registered)
	int? totalRideTime() {
		if (loops.isEmpty) return null;
		int time = 0;
		for (int i = 0; i < loops.length - 1; i++) {
			time += loops[i].timeToVet ?? 0;
		}
		time += loops.last.timeToArrival ?? 0;
		return time;
	}

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


	int? idealFinishTime() => category.idealSpeed == null ? null :
		category.startTime + startOffsetSecs + category.idealRideTime()! + category.totalRestTime();
	int? minFinishTime() => category.minSpeed == null ? null :
		category.startTime + startOffsetSecs + category.minRideTime()! + category.totalRestTime();
	int? maxFinishTime() => category.maxSpeed == null ? null :
		category.startTime + startOffsetSecs + category.maxRideTime()! + category.totalRestTime();

	static int byClassDistanceAndEid(Equipage a, Equipage b)
		=> a.compareClassAndEid(b);
	int compareClassAndEid(Equipage eq) {
		int c = eq.category.distance() - category.distance();
		return c != 0 ? c : compareEid(eq);
	}

	static int byEid(Equipage a, Equipage b)
		=> a.compareEid(b);
	int compareEid(Equipage eq)
		=> eid - eq.eid;

	static int byRankAndEid(Equipage a, Equipage b)
		=> a.compareRankAndEid(b);
	int compareRankAndEid(Equipage eq) {
		int cmp = compareRank(eq);
		return cmp != 0 ? cmp : eid - eq.eid;
	}

	static int byRank(Equipage a, Equipage b)
		=> a.compareRank(b);
	int compareRank(Equipage eq) {
		assert(category == eq.category, "Tried to compare rank across categories");

		// check for dnf
		if (isOut != eq.isOut) {
			if (isOut) return 1;
			return -1;
		}

		if (isFinished != eq.isFinished) {
			if (isFinished) return -1;
			return 1;
		} else if (isFinished && category.idealSpeed != null) {
			// CHECK: if this works
			// TODO: avoid null checks
			int dif = (loops.last.arrival! - idealFinishTime()!).abs();
			int eqdif = (eq.loops.last.arrival! - eq.idealFinishTime()!).abs();
			return dif - eqdif;
		}

		if (category.clearRound) {
			return 0;
		}

		if (currentLoop != eq.currentLoop)
			// largest loop
			return (eq.currentLoop ?? -1) - (currentLoop ?? -1);
		if (currentLoop == null)
			// before preExam
			return 0;

		var l = loops[currentLoop!];
		var eql = eq.loops[currentLoop!];
		if (l.vet != eql.vet && !isFinalLoop)
			// first vet time, unless final loop
			return (l.vet ?? UNIX_FUTURE) - (eql.vet ?? UNIX_FUTURE);
		if (l.arrival != eql.arrival)
			// first arrival time
			return (l.arrival ?? UNIX_FUTURE) - (eql.arrival ?? UNIX_FUTURE);
		if (l.expDeparture != eql.expDeparture)
			// first expected departure
			return (l.expDeparture ?? UNIX_FUTURE) - (eql.expDeparture ?? UNIX_FUTURE);

		return 0;
	}

	JSON toJson() => _$EquipageToJson(this);
	factory Equipage.fromJson(JSON json) =>
		_$EquipageFromJson(json);

	String toString() {
		return "${category.name} $eid $rider";
	}

}
