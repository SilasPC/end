library common;

import 'package:common/util.dart';
import 'EventModel.dart';
import 'package:json_annotation/json_annotation.dart';
import 'models/glob.dart';

// MUST RUN REPLACE ON PART AFTER BUILD:
// replace		<String, dynamic>\{\n(\s+)
// with			$0'kind': instance.kind,\n$1
part 'EnduranceEvent.g.dart';

abstract class EnduranceEvent extends Event<Model> {
	EnduranceEvent(super.time, super.kind, super.author);

	@override
	bool build(EventModel<Model> m) {
		try {
			return safeBuild(m);
		} catch (e, t) {
			m.model.errors.add(EventError(m.buildIndex, "$e $t"));
			return false;
		}
	}

	bool safeBuild(EventModel<Model> m);

	bool affectsEquipage(int eid);

	@override
	List get props => [time, kind, author];

}

EnduranceEvent eventFromJSON(JSON json) {
	String kind = json["kind"];
	switch (kind) {
		case "init":
			return InitEvent.fromJson(json);
		case "exam":
			return ExamEvent.fromJson(json);
		case "arrival":
			return ArrivalEvent.fromJson(json);
		case "departure":
			return DepartureEvent.fromJson(json);
		case "vet":
			return VetEvent.fromJson(json);
		case "start-clearance":
			return StartClearanceEvent.fromJson(json);
		case "retire":
			return RetireEvent.fromJson(json);
		case "change-category":
			return ChangeCategoryEvent.fromJson(json);
		case "disqualify":
			return DisqualifyEvent.fromJson(json);
		default:
			throw new Exception("could not parse event kind $kind");
	}
}

@JsonSerializable()
class InitEvent extends EnduranceEvent {
	Model model;
	InitEvent(String author, this.model) : super(0, "init", author);

	JSON toJson() => _$InitEventToJson(this);
	factory InitEvent.fromJson(JSON json) =>
		_$InitEventFromJson(json);

	@override
	bool safeBuild(EventModel<Model> m) {
		if (m.model.rideName == "") {
			m.model = model.clone();
			return true;
		}
		return false;
	}

	bool affectsEquipage(int eid) => false;

	@override
	String toString() => "Initializes model";
	
	@override
	List get props => super.props;

}

@JsonSerializable()
class DisqualifyEvent extends EnduranceEvent {
	int eid;
	String reason;
	DisqualifyEvent(String author, int time, this.eid, this.reason):
		super(time, "disqualify", author);

	JSON toJson() => _$DisqualifyEventToJson(this);
	factory DisqualifyEvent.fromJson(JSON json) =>
		_$DisqualifyEventFromJson(json);
	
	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.dsqReason != null) {
			m.model.errors.add(EventError(m.buildIndex, "${eid} double dsq: ${reason}"));
			return false;
		}
		eq.dsqReason = reason;
		eq.status = EquipageStatus.DNF;
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() => "Disqualifies $eid for '$reason'";
	
	@override
	List get props => super.props..addAll([eid, reason]);

}

@JsonSerializable()
class ChangeCategoryEvent extends EnduranceEvent {
	int eid;
	String category;
	ChangeCategoryEvent(String author, int time, this.eid, this.category):
		super(time, "change-category", author);

	JSON toJson() => _$ChangeCategoryEventToJson(this);
	factory ChangeCategoryEvent.fromJson(JSON json) =>
		_$ChangeCategoryEventFromJson(json);
	
	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.status != EquipageStatus.WAITING) {
			m.model.errors.add(EventError(m.buildIndex, "${eid} category change, status ${eq.status}"));
			return false;
		}
		var cat = m.model.categories[category]!;
		eq.category.equipages.remove(eq);
		eq.category = cat;
		cat.equipages.add(eq);
		// todo: change start no
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() => "Moves $eid to $category";
	
	@override
	List get props => super.props..addAll([eid, category]);

}

@JsonSerializable()
class RetireEvent extends EnduranceEvent {

	int eid;
	RetireEvent(String author, int time, this.eid):
		super(time, "retire", author);

	JSON toJson() => _$RetireEventToJson(this);
	factory RetireEvent.fromJson(JSON json) =>
		_$RetireEventFromJson(json);

	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.status != EquipageStatus.RESTING) {
			m.model.warnings.add(EventError(m.buildIndex, "Retire ${eq.eid} when status is ${eq.status.toString()}"));
		}
		eq.status = EquipageStatus.RETIRED;
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() => "Retires $eid";
	
	@override
	List get props => super.props..addAll([eid]);

}

@JsonSerializable()
class ExamEvent extends EnduranceEvent {
	int eid;
	int? loop;
	VetData data;
	ExamEvent(String author, int time,this.eid,this.data,this.loop):
		super(time, "exam", author);

	JSON toJson() => _$ExamEventToJson(this);
	factory ExamEvent.fromJson(JSON json) =>
		_$ExamEventFromJson(json);
		
	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		int cl = eq.currentLoop ?? -1;
		if (eq.status != EquipageStatus.VET) {
			m.model.errors.add(EventError(m.buildIndex, "${eid} not ready for gate"));
			return false;
		}
		if ((loop ?? -1) != cl) {
			m.model.warnings.add(EventError(m.buildIndex, "${eid} exam out of order loop ${loop}, current $cl"));
		}
		bool p = data.passed;
		if (eq.currentLoop == null) {
			// preExam
			if (p) eq.currentLoop = 0;
			eq.preExam = data;
			eq.loops = eq.category.loops.map((l) => LoopData(l)).toList();
			eq.loops.first.expDeparture = eq.category.startTime;
		} else {
			// regular gate
			var l = eq.currentLoopData!;
			l.data = data;
			// todo: check < 20min if passed
			if (p && eq.currentLoop! != eq.loops.length - 1) {
				// next loop
				var next = eq.currentLoop = eq.currentLoop! + 1;
				if (l.vet != null)
					eq.loops[next].expDeparture = l.vet! + l.loop.restTime * 60;
			}
		}
		eq.updateStatus();
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() =>
		"${data.passed ? "Approves " : "Rejects "} $eid's loop ${(loop ?? -1) + 1} exam";

	@override
	List get props => super.props..addAll([eid, loop]);

}

@JsonSerializable()
class VetEvent extends EnduranceEvent {
	int eid;
	int loop;
	VetEvent(String author, int time,this.eid,this.loop):
		super(time, "vet", author);
	
	JSON toJson() => _$VetEventToJson(this);
	factory VetEvent.fromJson(JSON json) =>
		_$VetEventFromJson(json);
	
	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.status != EquipageStatus.COOLING) {
			m.model.errors.add(EventError(m.buildIndex, "${eid} not ready for gate"));
			return false;
		}
		if (loop != eq.currentLoop) {
			m.model.warnings.add(EventError(m.buildIndex, "${eid} departure out of order loop ${loop}"));
		}
		var l = eq.loops[loop];
		l.vet = time;
		eq.updateStatus();
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() => "Registers vet for $eid loop ${loop+1}";

	@override
	List get props => super.props..addAll([eid, loop]);

}

@JsonSerializable()
class ArrivalEvent extends EnduranceEvent {
	int loop;
	int eid;
	ArrivalEvent(String author, int time,this.eid,this.loop):
		super(time, "arrival", author);
	
	JSON toJson() => _$ArrivalEventToJson(this);
	factory ArrivalEvent.fromJson(JSON json) =>
		_$ArrivalEventFromJson(json);

	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (loop != eq.currentLoop) {
			m.model.warnings.add(EventError(m.buildIndex, "${eid} arrival out of order loop ${loop}"));
		}
		if (eq.status != EquipageStatus.RIDING) {
			m.model.errors.add(EventError(m.buildIndex, "${eid} not ready for gate"));
			return false;
		}
		var l = eq.loops[loop];
		l.arrival = time;
		eq.updateStatus();
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() => "Registers arrival for $eid loop ${loop+1}";

	@override
	List get props => super.props..addAll([eid, loop]);

}

@JsonSerializable()
class StartClearanceEvent extends EnduranceEvent {
	List<int> eids;
	StartClearanceEvent(String author, int time, this.eids):
		super(time, "start-clearance", author);

	JSON toJson() => _$StartClearanceEventToJson(this);
	factory StartClearanceEvent.fromJson(JSON json) =>
		_$StartClearanceEventFromJson(json);

	@override
	bool safeBuild(EventModel<Model> m) {
		bool fail = false;
		for (int eid in eids) {
			var eq = m.model.equipages[eid]!;
			if (eq.status != EquipageStatus.WAITING) {
				m.model.errors.add(EventError(m.buildIndex, "Cannot clear $eid for start"));
				fail = true;
			} else {
				eq.status = EquipageStatus.VET;
			}
		}
		return !fail;
	}

	bool affectsEquipage(int eid) => eids.contains(eid);

	@override
	String toString() => "Clears $eids for start";

	@override
	List get props => super.props..addAll([eids]);
	
}

@JsonSerializable()
class DepartureEvent extends EnduranceEvent {
	int eid;
	int loop;
	DepartureEvent(String author, int time,this.eid,this.loop):
		super(time, "departure", author);
	
	JSON toJson() => _$DepartureEventToJson(this);
	factory DepartureEvent.fromJson(JSON json) =>
		_$DepartureEventFromJson(json);
	@override
	bool safeBuild(EventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (loop != eq.currentLoop) {
			m.model.warnings.add(EventError(m.buildIndex, "${eid} departure out of order loop ${loop}"));
		}
		if (eq.status != EquipageStatus.RESTING) {
			m.model.errors.add(EventError(m.buildIndex, "${eid} not ready for gate"));
			return false;
		}
		var l = eq.loops[loop];
		if (time - l.expDeparture! > 15 * 60) {
			m.model.warnings.add(EventError(m.buildIndex, "$eid late departure"));
		}
		l.departure = time;
		eq.updateStatus();
		return true;
	}

	bool affectsEquipage(int eid) => eid == this.eid;

	@override
	String toString() => "Registers departure for $eid loop ${loop+1}";

	@override
	List get props => super.props..addAll([eid, loop]);
	
}
