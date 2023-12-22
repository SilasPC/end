// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EventError.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenericError _$GenericErrorFromJson(Map<String, dynamic> json) => GenericError(
      json['causedBy'] as int,
      json['description'] as String,
    );

Map<String, dynamic> _$GenericErrorToJson(GenericError instance) =>
    <String, dynamic>{
      'type': instance.type,
      'causedBy': instance.causedBy,
      'description': instance.description,
    };

GenericEquipageError _$GenericEquipageErrorFromJson(
        Map<String, dynamic> json) =>
    GenericEquipageError(
      json['eid'] as int,
      json['causedBy'] as int,
      json['description'] as String,
    );

Map<String, dynamic> _$GenericEquipageErrorToJson(
        GenericEquipageError instance) =>
    <String, dynamic>{
      'type': instance.type,
      'causedBy': instance.causedBy,
      'description': instance.description,
      'eid': instance.eid,
    };

MissingDataError _$MissingDataErrorFromJson(Map<String, dynamic> json) =>
    MissingDataError(
      json['eid'] as int,
      json['causedBy'] as int,
      json['description'] as String,
    );

Map<String, dynamic> _$MissingDataErrorToJson(MissingDataError instance) =>
    <String, dynamic>{
      'type': instance.type,
      'causedBy': instance.causedBy,
      'description': instance.description,
      'eid': instance.eid,
    };

GateError _$GateErrorFromJson(Map<String, dynamic> json) => GateError(
      json['eid'] as int,
      $enumDecode(_$LoopGateEnumMap, json['gate']),
      json['causedBy'] as int,
      json['description'] as String,
    );

Map<String, dynamic> _$GateErrorToJson(GateError instance) => <String, dynamic>{
      'type': instance.type,
      'causedBy': instance.causedBy,
      'description': instance.description,
      'eid': instance.eid,
      'gate': _$LoopGateEnumMap[instance.gate]!,
    };

const _$LoopGateEnumMap = {
  LoopGate.DEPARTURE: 'DEPARTURE',
  LoopGate.ARRIVAL: 'ARRIVAL',
  LoopGate.VET: 'VET',
  LoopGate.EXAM: 'EXAM',
};
