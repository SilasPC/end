
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

	bool get isWAITING => this == WAITING;
	bool get isRIDING => this == RIDING;
	bool get isVET => this == VET;
	bool get isDNF => this == DNF;
	bool get isFINISHED => this == FINISHED;
	bool get isCOOLING => this == COOLING;
	bool get isRESTING => this == RESTING;
	bool get isRETIRED => this == RETIRED;

	/// indicates equipage failed to complete competition
	bool get isOut => isDNF || isRETIRED;

	/// indicates equipage successfully completed competition
	bool get isFinished => isFINISHED;

	/// indicates equipage no longer competing
	bool get isEnded => isDNF || isFINISHED || isRETIRED;

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

	int? get currentLoopOneIndexed =>
		switch (currentLoop) {
			int currentLoop => currentLoop + 1,
			null => null
		};

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
		if (currentLoop case int cur) {
			if (currentLoopData case LoopData ld) {
				if (ld.vet case int vet) {
					loops[cur].expDeparture = vet + ld.loop.restTime * 60;
				}
			}
			currentLoop = cur + 1;
		}
		return true;
	}

	LoopData? get currentLoopData =>
		switch (currentLoop) {
			(int i) => loops[i],
			_ => null
		};

	LoopData? get previousLoopData =>
		switch (currentLoop) {
			(int i) when i > 0 => loops[i-1],
			_ => null
		};

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

	int get startTime => category.startTime + startOffsetSecs;

	int? idealFinishTime() => 
		switch (category.idealRideTime()) {
			int idealRideTime => startTime + idealRideTime + category.totalRestTime(),
			_ => null
		};

	int? minFinishTime() => 
		switch (category.minRideTime()) {
			int minRideTime => startTime + minRideTime + category.totalRestTime(),
			_ => null
		};

	int? maxFinishTime() => 
		switch (category.maxRideTime()) {
			int maxRideTime => startTime + maxRideTime + category.totalRestTime(),
			_ => null
		};

	int? idealTimeError() =>
		switch ((loops.lastOrNull?.arrival, idealFinishTime())) {
			(int arrival, int time) when isFinalLoop => (time - arrival).abs(),
			_ => null
		};

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
			switch ((idealTimeError(), eq.idealTimeError())) {
				case (int dif, int eqdif):
					return dif - eqdif;
			}
			// should not happen
			return 0;
		}

		if (category.clearRound) {
			return 0;
		}

		int cl;
		if (currentLoop != eq.currentLoop)
			// largest loop
			return (eq.currentLoop ?? -1) - (currentLoop ?? -1);
		if (currentLoop case int currentLoop) {
			cl = currentLoop;
		} else {
			// before preExam
			return 0;
		}

		var l = loops[cl];
		var eql = eq.loops[cl];
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
