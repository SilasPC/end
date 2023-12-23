library common;

import 'package:common/consts.dart';
import 'package:common/util.dart';
import 'package:equatable/equatable.dart';
import 'EventModel.dart';
import 'package:json_annotation/json_annotation.dart';
import 'models/glob.dart';

part 'EnduranceEvent.g.dart';

sealed class EnduranceEvent extends Event<EnduranceModel> with EquatableMixin {
  EnduranceEvent(super.author, super.time);

  @override
  void build(EventModel<EnduranceModel> m) {
    try {
      safeBuild(m);
    } catch (e, t) {
      m.model.errors.add(GenericError(m.buildIndex, "$e $t"));
    }
  }

  EnduranceEvent copyWithTime(int time) =>
      eventFromJSON(toJson()..["time"] = time);

  factory EnduranceEvent.fromJson(JSON json) => eventFromJSON(json);

  void safeBuild(EventModel<EnduranceModel> m);

  bool affectsEquipage(int eid);

  @override
  List get props => [time, author];
}

sealed class GateEvent extends EnduranceEvent {
  @JsonKey(includeFromJson: false, includeToJson: false)
  LoopGate get gate;
  int? get loopHint;
  final int eid;

  GateEvent(super.author, super.time, this.eid);

  bool checkSkip(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    int cl = eq.currentLoop ?? -1;
    if (eq.currentLoopData?.nextGate case LoopGate next) {
      if (gate.isBefore(next)) {
        if (eq.skipLoop()) {
          m.model.errors
              .add(MissingDataError(eid, m.buildIndex, "loop skipped"));
        } else {
          m.model.errors
              .add(MissingDataError(eid, m.buildIndex, "loop skip fail"));
          return false;
        }
      }
    } else if (eq.status != gate.expectedStatus) {
      m.model.errors
          .add(GateError(eid, gate, m.buildIndex, "not ready for gate"));
    }
    if (loopHint case int loopHint when loopHint != cl) {
      m.model.errors.add(GateError(eid, gate, m.buildIndex,
          "exam out of order loop ${loopHint}, current $cl"));
      if (loopHint > cl) {
        cl = eq.currentLoop = loopHint;
      }
    }
    return true;
  }

  bool affectsEquipage(int eid) => eid == this.eid;
}

EnduranceEvent eventFromJSON(JSON json) {
  String type = json["type"];
  switch (type) {
    case "InitEvent":
      return InitEvent.fromJson(json);
    case "ExamEvent":
      return ExamEvent.fromJson(json);
    case "ArrivalEvent":
      return ArrivalEvent.fromJson(json);
    case "DepartureEvent":
      return DepartureEvent.fromJson(json);
    case "VetEvent":
      return VetEvent.fromJson(json);
    case "StartClearanceEvent":
      return StartClearanceEvent.fromJson(json);
    case "RetireEvent":
      return RetireEvent.fromJson(json);
    case "ChangeCategoryEvent":
      return ChangeCategoryEvent.fromJson(json);
    case "DisqualifyEvent":
      return DisqualifyEvent.fromJson(json);
    default:
      throw new Exception("could not parse event kind $type");
  }
}

@JsonSerializable()
class InitEvent extends EnduranceEvent {
  final EnduranceModel model;
  InitEvent(super.author, super.time, this.model);

  JSON toJson() => _$InitEventToJson(this);
  factory InitEvent.fromJson(JSON json) => _$InitEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    if (m.model.rideName == "") {
      m.model = model.clone();
    }
  }

  bool affectsEquipage(int eid) => false;

  @override
  String toString() => "Initializes model";

  @override
  List get props => super.props;
}

@JsonSerializable()
class DisqualifyEvent extends EnduranceEvent {
  final int eid;
  final String reason;
  DisqualifyEvent(super.author, super.time, this.eid, this.reason);

  JSON toJson() => _$DisqualifyEventToJson(this);
  factory DisqualifyEvent.fromJson(JSON json) =>
      _$DisqualifyEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (eq.dsqReason != null) {
      m.model.errors.add(
          GenericEquipageError(eid, m.buildIndex, "double dsq: ${reason}"));
      return;
    }
    eq.dsqReason = reason;
    eq.status = EquipageStatus.DNF;
  }

  bool affectsEquipage(int eid) => eid == this.eid;

  @override
  String toString() => "Disqualifies $eid for '$reason'";

  @override
  List get props => super.props..addAll([eid, reason]);
}

@JsonSerializable()
class ChangeCategoryEvent extends EnduranceEvent {
  final int eid;
  final String category;
  ChangeCategoryEvent(super.author, super.time, this.eid, this.category);

  JSON toJson() => _$ChangeCategoryEventToJson(this);
  factory ChangeCategoryEvent.fromJson(JSON json) =>
      _$ChangeCategoryEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (eq.status != EquipageStatus.WAITING) {
      m.model.errors.add(GenericEquipageError(
          eid, m.buildIndex, "category change while status ${eq.status}"));
      return;
    }
    var cat = m.model.categories[category]!;
    eq.category.equipages.remove(eq);
    eq.category = cat;
    cat.equipages.add(eq);
    // FEAT: change start no
    // ^^^^ note that this may affect logic that
    // expects eids to remain constant
  }

  bool affectsEquipage(int eid) => eid == this.eid;

  @override
  String toString() => "Moves $eid to $category";

  @override
  List get props => super.props..addAll([eid, category]);
}

@JsonSerializable()
class RetireEvent extends EnduranceEvent {
  final int eid;
  RetireEvent(super.author, super.time, this.eid);

  JSON toJson() => _$RetireEventToJson(this);
  factory RetireEvent.fromJson(JSON json) => _$RetireEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (eq.status != EquipageStatus.RESTING) {
      m.model.errors.add(GenericEquipageError(
          eid, m.buildIndex, "Retire when status is ${eq.status.name}"));
    }
    eq.status = EquipageStatus.RETIRED;
  }

  bool affectsEquipage(int eid) => eid == this.eid;

  @override
  String toString() => "Retires $eid";

  @override
  List get props => super.props..addAll([eid]);
}

@JsonSerializable()
class ExamEvent extends GateEvent {
  final int? loopHint;
  final VetData data;
  LoopGate get gate => LoopGate.EXAM;
  ExamEvent(super.author, super.time, super.eid, this.data, this.loopHint);

  JSON toJson() => _$ExamEventToJson(this);
  factory ExamEvent.fromJson(JSON json) => _$ExamEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (!checkSkip(m)) return;
    if (eq.currentLoopData case LoopData ld) {
      // regular gate
      ld.data = data;
      if (data.passed) {
        if (eq.currentLoop case int currentLoop when !eq.isFinalLoop) {
          // next loop
          var next = eq.currentLoop = currentLoop + 1;
          if (ld.vet case int vetTime) {
            eq.loops[next].expDeparture = vetTime + ld.loop.restTime * 60;
          }
          eq.status = EquipageStatus.RESTING;
        } else {
          // finish
          var minFin = eq.minFinishTime();
          var maxFin = eq.maxFinishTime();
          if (minFin != null && time < minFin) {
            m.model.errors.add(GateError(
                eid, LoopGate.EXAM, m.buildIndex, "finished too early"));
          }
          if (maxFin != null && time > maxFin) {
            m.model.errors.add(GateError(
                eid, LoopGate.EXAM, m.buildIndex, "finished too late"));
          }
          eq.status = EquipageStatus.FINISHED;
        }
      } else {
        eq.status = EquipageStatus.DNF;
      }
      if (ld.vet case int vetTime
          when data.passed && time > vetTime + COOL_TIME) {
        m.model.errors.add(GateError(
            eid, LoopGate.EXAM, m.buildIndex, "too late to pass exam"));
      }
      ld.nextGate = null;
    } else {
      // preExam
      if (data.passed) eq.currentLoop = 0;
      eq.preExam = data;
      eq.status = data.passed ? EquipageStatus.RESTING : EquipageStatus.DNF;
      eq.loops.first.expDeparture = eq.category.startTime;
    }
    // FEAT: check for missing data when ended
  }

  @override
  String toString() =>
      "${data.passed ? "Approves " : "Rejects "} $eid's loop ${(loopHint ?? -1) + 1} exam";

  @override
  List get props => super.props..addAll([eid, loopHint]);
}

@JsonSerializable()
class VetEvent extends GateEvent {
  final int? loopHint;
  VetEvent(super.author, super.time, super.eid, this.loopHint);

  LoopGate get gate => LoopGate.VET;
  JSON toJson() => _$VetEventToJson(this);
  factory VetEvent.fromJson(JSON json) => _$VetEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (!checkSkip(m)) return;
    if (eq.currentLoopData case LoopData ld) {
      ld.vet = time;
      ld.nextGate = LoopGate.EXAM;
      eq.status = EquipageStatus.EXAM;
    }
  }

  @override
  String toString() => "Registers vet for $eid loop ${(loopHint ?? 0) + 1}";

  @override
  List get props => super.props..addAll([eid, loopHint]);
}

@JsonSerializable()
class ArrivalEvent extends GateEvent {
  final int? loopHint;

  LoopGate get gate => LoopGate.ARRIVAL;
  ArrivalEvent(super.author, super.time, super.eid, this.loopHint);

  JSON toJson() => _$ArrivalEventToJson(this);
  factory ArrivalEvent.fromJson(JSON json) => _$ArrivalEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (!checkSkip(m)) return;
    if (eq.currentLoopData case LoopData ld) {
      ld.arrival = time;
      ld.nextGate = LoopGate.VET;
      eq.status = EquipageStatus.COOLING;
    }
  }

  @override
  String toString() => "Registers arrival for $eid loop ${(loopHint ?? 0) + 1}";

  @override
  List get props => super.props..addAll([eid, loopHint]);
}

@JsonSerializable()
class StartClearanceEvent extends EnduranceEvent {
  final List<int> eids;
  StartClearanceEvent(super.author, super.time, this.eids);

  JSON toJson() => _$StartClearanceEventToJson(this);
  factory StartClearanceEvent.fromJson(JSON json) =>
      _$StartClearanceEventFromJson(json);

  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    for (int eid in eids) {
      var eq = m.model.equipages[eid]!;
      if (eq.status != EquipageStatus.WAITING) {
        m.model.errors.add(
            GenericEquipageError(eid, m.buildIndex, "Cannot clear for start"));
      } else {
        eq.status = EquipageStatus.EXAM;
      }
    }
  }

  bool affectsEquipage(int eid) => eids.contains(eid);

  @override
  String toString() => "Clears $eids for start";

  @override
  List get props => super.props..addAll([eids]);
}

@JsonSerializable()
class DepartureEvent extends GateEvent {
  final int? loopHint;
  LoopGate get gate => LoopGate.DEPARTURE;
  DepartureEvent(super.author, super.time, super.eid, this.loopHint);

  JSON toJson() => _$DepartureEventToJson(this);
  factory DepartureEvent.fromJson(JSON json) => _$DepartureEventFromJson(json);
  @override
  void safeBuild(EventModel<EnduranceModel> m) {
    var eq = m.model.equipages[eid]!;
    if (!checkSkip(m)) return;
    var expDep = eq.currentLoopData?.expDeparture;
    if (expDep case int expDep) {
      if (time - expDep > MAX_DEPART_DELAY) {
        // TODO: what to do? this is not really an "error"
        // rather, it should be a warning if the equipage is accepted
        // despite this
        m.model.errors.add(GateError(eid, gate, m.buildIndex, "too late"));
      } else if (time < expDep) {
        m.model.errors.add(GateError(eid, gate, m.buildIndex, "too early"));
      }
    }
    if (eq.currentLoopData case LoopData ld) {
      ld.departure = time;
      ld.nextGate = LoopGate.ARRIVAL;
      eq.status = EquipageStatus.RIDING;
    }
  }

  @override
  String toString() =>
      "Registers departure for $eid loop ${(loopHint ?? 0) + 1}";

  @override
  List get props => super.props..addAll([eid, loopHint]);
}
