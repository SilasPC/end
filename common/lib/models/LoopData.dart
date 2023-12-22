import 'package:json_annotation/json_annotation.dart';

import '../util.dart';
import 'glob.dart';

part "LoopData.g.dart";

enum LoopGate {
  DEPARTURE(0),
  ARRIVAL(1),
  VET(2),
  EXAM(3);

  final int _disc;
  const LoopGate(this._disc);

  bool isBefore(LoopGate other) => _disc < other._disc;
}

@JsonSerializable(constructor: "raw")
class LoopData extends IJSON {
  @JsonKey(includeFromJson: false, includeToJson: false)
  LoopGate? nextGate;

  int? expDeparture;
  int? departure;
  int? arrival;
  int? vet;
  VetData? data;

  @JsonKey(includeFromJson: false, includeToJson: false)
  late Loop loop;

  LoopData(this.loop) {
    nextGate = switch (this) {
      LoopData(data: VetData _) => null,
      LoopData(vet: int _) => LoopGate.EXAM,
      LoopData(arrival: int _) => LoopGate.VET,
      LoopData(departure: int _) => LoopGate.ARRIVAL,
      _ => LoopGate.DEPARTURE
    };
  }
  LoopData.raw();

  double? speed({bool finish = false}) {
    int? t = finish ? timeToArrival : timeToVet;
    if (t == null) return null;
    return loop.distance * 3600 / t;
  }

  int? get recoveryTime => switch ((arrival, vet)) {
        (int arrival, int vet) => vet - arrival,
        _ => null
      };

  int? get timeToVet => switch ((expDeparture, vet)) {
        (int expDeparture, int vet) => vet - expDeparture,
        _ => null
      };

  int? get timeToArrival => switch ((expDeparture, arrival)) {
        (int expDeparture, int arrival) => arrival - expDeparture,
        _ => null
      };

  JSON toJson() => _$LoopDataToJson(this);
  factory LoopData.fromJson(JSON json) => _$LoopDataFromJson(json);
}
