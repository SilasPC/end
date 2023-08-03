library common;

import 'package:common/util.dart';
import 'AbstractEventModel.dart';
import 'package:json_annotation/json_annotation.dart';

import 'models/glob.dart';

// MUST RUN REPLACE ON PART AFTER BUILD:
// replace		<String, dynamic>\{\n(\s+)
// with			$0'kind': instance.kind,\n$1
part "Event.g.dart";

Event<Model> eventFromJSON(JSON json) {
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
class InitEvent extends Event<Model> {
	Model model;
	InitEvent(String author, this.model) : super(0, "init", author);

	JSON toJson() => _$InitEventToJson(this);
	factory InitEvent.fromJson(JSON json) =>
		_$InitEventFromJson(json);

	@override
	bool build(AbstractEventModel<Model> m) {
		if (m.events.first == this) {
			m.model = model;
			return true;
		}
		return false;
	}

	@override
	String toString() => "Initializes model";

}

@JsonSerializable()
class DisqualifyEvent extends Event<Model> {
	int eid;
	String reason;
	DisqualifyEvent(String author, int time, this.eid, this.reason):
		super(time, "disqualify", author);

	JSON toJson() => _$DisqualifyEventToJson(this);
	factory DisqualifyEvent.fromJson(JSON json) =>
		_$DisqualifyEventFromJson(json);
	
	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.dsqReason != null) {
			m.model.errors.add(EventError.of("${eid} double dsq: ${reason}", this));
			return false;
		}
		eq.dsqReason = reason;
		eq.status = EquipageStatus.DNF;
		return true;
	}

	@override
	String toString() => "Disqualifies $eid for '$reason'";
	
}

@JsonSerializable()
class ChangeCategoryEvent extends Event<Model> {
	int eid;
	String category;
	ChangeCategoryEvent(String author, int time, this.eid, this.category):
		super(time, "change-category", author);

	JSON toJson() => _$ChangeCategoryEventToJson(this);
	factory ChangeCategoryEvent.fromJson(JSON json) =>
		_$ChangeCategoryEventFromJson(json);
	
	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.status != EquipageStatus.WAITING) {
			m.model.errors.add(EventError.of("${eid} category change, status ${eq.status}", this));
			return false;
		}
		var cat = m.model.categories[category]!;
		eq.category.equipages.remove(eq);
		eq.category = cat;
		cat.equipages.add(eq);
		// todo: change start no
		return true;
	}

	@override
	String toString() => "Moves $eid to $category";

}

@JsonSerializable()
class RetireEvent extends Event<Model> {

	int eid;
	RetireEvent(String author, int time, this.eid):
		super(time, "retire", author);

	JSON toJson() => _$RetireEventToJson(this);
	factory RetireEvent.fromJson(JSON json) =>
		_$RetireEventFromJson(json);

	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.status != EquipageStatus.RESTING) {
			m.model.warnings.add(EventError.of("Retire ${eq.eid} when status is ${eq.status.toString()}", this));
		}
		eq.status = EquipageStatus.RETIRED;
		return true;
	}

	@override
	String toString() => "Retires $eid";

}

@JsonSerializable()
class ExamEvent extends Event<Model> {
	int eid;
	int? loop;
	VetData data;
	ExamEvent(String author, int time,this.eid,this.data,this.loop):
		super(time, "exam", author);

	JSON toJson() => _$ExamEventToJson(this);
	factory ExamEvent.fromJson(JSON json) =>
		_$ExamEventFromJson(json);
		
	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		int cl = eq.currentLoop ?? -1;
		if (eq.status != EquipageStatus.VET) {
			m.model.errors.add(EventError.of("${eid} not ready for gate", this));
			return false;
		}
		if ((loop ?? -1) != cl) {
			m.model.warnings.add(EventError.of("${eid} exam out of order loop ${loop}, current $cl", this));
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
				// todo: assumes 40 minutes break
				if (l.vet != null)
					eq.loops[next].expDeparture = l.vet! + 40 * 60;
			}
		}
		eq.updateStatus();
		return true;
	}

	@override
	String toString() =>
		"${data.passed ? "Approves " : "Rejects "} $eid's loop ${(loop ?? -1) + 1} exam";

}

@JsonSerializable()
class VetEvent extends Event<Model> {
	int eid;
	int loop;
	VetEvent(String author, int time,this.eid,this.loop):
		super(time, "vet", author);
	
	JSON toJson() => _$VetEventToJson(this);
	factory VetEvent.fromJson(JSON json) =>
		_$VetEventFromJson(json);
	
	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (eq.status != EquipageStatus.COOLING) {
			m.model.errors.add(EventError.of("${eid} not ready for gate", this));
			return false;
		}
		if (loop != eq.currentLoop) {
			m.model.warnings.add(EventError.of("${eid} departure out of order loop ${loop}", this));
		}
		var l = eq.loops[loop];
		l.vet = time;
		eq.updateStatus();
		return true;
	}

	@override
	String toString() => "Registers vet for $eid loop ${loop+1}";

}

@JsonSerializable()
class ArrivalEvent extends Event<Model> {
	int loop;
	int eid;
	ArrivalEvent(String author, int time,this.eid,this.loop):
		super(time, "arrival", author);
	
	JSON toJson() => _$ArrivalEventToJson(this);
	factory ArrivalEvent.fromJson(JSON json) =>
		_$ArrivalEventFromJson(json);

	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (loop != eq.currentLoop) {
			m.model.warnings.add(EventError.of("${eid} arrival out of order loop ${loop}", this));
		}
		if (eq.status != EquipageStatus.RIDING) {
			m.model.errors.add(EventError.of("${eid} not ready for gate", this));
			return false;
		}
		var l = eq.loops[loop];
		l.arrival = time;
		eq.updateStatus();
		return true;
	}

	@override
	String toString() => "Registers arrival for $eid loop ${loop+1}";

}

@JsonSerializable()
class StartClearanceEvent extends Event<Model> {
	List<int> eids;
	StartClearanceEvent(String author, int time, this.eids):
		super(time, "start-clearance", author);

	JSON toJson() => _$StartClearanceEventToJson(this);
	factory StartClearanceEvent.fromJson(JSON json) =>
		_$StartClearanceEventFromJson(json);

	@override
	bool build(AbstractEventModel<Model> m) {
		bool fail = false;
		for (int eid in eids) {
			var eq = m.model.equipages[eid]!;
			if (eq.status != EquipageStatus.WAITING) {
				m.model.errors.add(EventError.of("Cannot clear $eid for start", this));
				fail = true;
			} else {
				eq.status = EquipageStatus.VET;
			}
		}
		return !fail;
	}

	@override
	String toString() => "Clears $eids for start";

}

@JsonSerializable()
class DepartureEvent extends Event<Model> {
	int eid;
	int loop;
	DepartureEvent(String author, int time,this.eid,this.loop):
		super(time, "departure", author);
	
	JSON toJson() => _$DepartureEventToJson(this);
	factory DepartureEvent.fromJson(JSON json) =>
		_$DepartureEventFromJson(json);
	@override
	bool build(AbstractEventModel<Model> m) {
		var eq = m.model.equipages[eid]!;
		if (loop != eq.currentLoop) {
			m.model.warnings.add(EventError.of("${eid} departure out of order loop ${loop}", this));
		}
		if (eq.status != EquipageStatus.RESTING) {
			m.model.errors.add(EventError.of("${eid} not ready for gate", this));
			return false;
		}
		var l = eq.loops[loop];
		l.departure = time;
		eq.updateStatus();
		return true;
	}

	@override
	String toString() => "Registers departure for $eid loop ${loop+1}";

}
