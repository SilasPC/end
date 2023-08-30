
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
	
	@JsonKey(ignore: true)
	late Category category;

	Equipage(this.eid, this.rider,this.horse, this.category);
	Equipage.raw(this.eid, this.rider,this.horse);

	LoopData? get currentLoopData =>
		currentLoop == null ? null : loops[currentLoop!];

	/// indicates this equipage failed to complete competition
	bool get isOut => status.isOut;
	/// indicates this equipage successfully completed competition
	bool get isFinished => status.isFinished;
	/// indicates this equipage no longer competing
	bool get isEnded => status.isEnded;

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
		if (l.vet != eql.vet && currentLoop! != eq.loops.length-1)
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
	
	JSON toJson() => _$EquipageToJson(this);
	factory Equipage.fromJson(JSON json) =>
		_$EquipageFromJson(json);

	String toString() {
		return "${category.name} $eid $rider";
	}

}
