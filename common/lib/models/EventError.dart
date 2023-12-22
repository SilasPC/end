import 'package:common/models/glob.dart';
import 'package:json_annotation/json_annotation.dart';
import '../util.dart';

part "EventError.g.dart";

sealed class EventError extends IJSON {
  @JsonKey(includeToJson: true, includeFromJson: false)
  String get type => runtimeType.toString();

  EventError(this.causedBy, this.description);

  /// The event index of the cause.
  final int causedBy;
  final String description;

  @override
  String toString() => "EventError($description)";

  factory EventError.fromJson(JSON json) => switch (json["type"]) {
        "GenericError" => GenericError.fromJson(json),
        "GenericEquipageError" => GenericEquipageError.fromJson(json),
        "MissingDataError" => MissingDataError.fromJson(json),
        "GateError" => GateError.fromJson(json),
        _ => throw Exception("unknown EventError type")
      };
}

@JsonSerializable()
final class GenericError extends EventError {
  GenericError(super.causedBy, super.description);

  JSON toJson() => _$GenericErrorToJson(this);
  factory GenericError.fromJson(JSON json) => _$GenericErrorFromJson(json);
}

sealed class EquipageError extends EventError {
  // FIXME: what if they change eid?
  final int eid;

  EquipageError(this.eid, super.causedBy, super.description);
}

@JsonSerializable()
final class GenericEquipageError extends EquipageError {
  GenericEquipageError(super.eid, super.causedBy, super.description);

  JSON toJson() => _$GenericEquipageErrorToJson(this);
  factory GenericEquipageError.fromJson(JSON json) =>
      _$GenericEquipageErrorFromJson(json);
}

@JsonSerializable()
final class MissingDataError extends EquipageError {
  MissingDataError(super.eid, super.causedBy, super.description);

  JSON toJson() => _$MissingDataErrorToJson(this);
  factory MissingDataError.fromJson(JSON json) =>
      _$MissingDataErrorFromJson(json);
}

@JsonSerializable()
final class GateError extends EquipageError {
  final LoopGate gate;
  GateError(super.eid, this.gate, super.causedBy, super.description);

  JSON toJson() => _$GateErrorToJson(this);
  factory GateError.fromJson(JSON json) => _$GateErrorFromJson(json);
}
