// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Loop _$LoopFromJson(Map<String, dynamic> json) => Loop(
      json['distance'] as int,
    );

Map<String, dynamic> _$LoopToJson(Loop instance) => <String, dynamic>{
      'distance': instance.distance,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      json['name'] as String,
      (json['loops'] as List<dynamic>)
          .map((e) => Loop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      'name': instance.name,
      'loops': instance.loops,
    };

EventId _$EventIdFromJson(Map<String, dynamic> json) => EventId(
      json['time'] as int,
      json['author'] as String,
    );

Map<String, dynamic> _$EventIdToJson(EventId instance) => <String, dynamic>{
      'time': instance.time,
      'author': instance.author,
    };

EventError _$EventErrorFromJson(Map<String, dynamic> json) => EventError(
      json['description'] as String,
      EventId.fromJson(json['causedBy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventErrorToJson(EventError instance) =>
    <String, dynamic>{
      'description': instance.description,
      'causedBy': instance.causedBy,
    };

Model _$ModelFromJson(Map<String, dynamic> json) => Model()
  ..rideName = json['rideName'] as String
  ..categories = (json['categories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, Category.fromJson(e as Map<String, dynamic>)),
  )
  ..errors = (json['errors'] as List<dynamic>)
      .map((e) => EventError.fromJson(e as Map<String, dynamic>))
      .toList()
  ..warnings = (json['warnings'] as List<dynamic>)
      .map((e) => EventError.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
      'rideName': instance.rideName,
      'categories': instance.categories,
      'errors': instance.errors,
      'warnings': instance.warnings,
    };

Equipage _$EquipageFromJson(Map<String, dynamic> json) => Equipage.raw(
      json['eid'] as int,
      json['rider'] as String,
      json['horse'] as String,
    )
      ..status = EquipageStatus.fromJson(json['status'])
      ..preExam = json['preExam'] == null
          ? null
          : VetData.fromJson(json['preExam'] as Map<String, dynamic>)
      ..loops = (json['loops'] as List<dynamic>)
          .map((e) => LoopData.fromJson(e as Map<String, dynamic>))
          .toList()
      ..currentLoop = json['currentLoop'] as int?
      ..dsqReason = json['dsqReason'] as String?;

Map<String, dynamic> _$EquipageToJson(Equipage instance) => <String, dynamic>{
      'status': instance.status,
      'eid': instance.eid,
      'rider': instance.rider,
      'horse': instance.horse,
      'preExam': instance.preExam,
      'loops': instance.loops,
      'currentLoop': instance.currentLoop,
      'dsqReason': instance.dsqReason,
    };

LoopData _$LoopDataFromJson(Map<String, dynamic> json) => LoopData.raw()
  ..expDeparture = json['expDeparture'] as int?
  ..departure = json['departure'] as int?
  ..arrival = json['arrival'] as int?
  ..vet = json['vet'] as int?
  ..data = json['data'] == null
      ? null
      : VetData.fromJson(json['data'] as Map<String, dynamic>);

Map<String, dynamic> _$LoopDataToJson(LoopData instance) => <String, dynamic>{
      'expDeparture': instance.expDeparture,
      'departure': instance.departure,
      'arrival': instance.arrival,
      'vet': instance.vet,
      'data': instance.data,
    };

VetData _$VetDataFromJson(Map<String, dynamic> json) => VetData(
      json['passed'] as bool,
    )
      ..hr1 = json['hr1'] as int?
      ..hr2 = json['hr2'] as int?
      ..resp = json['resp'] as int?
      ..mucMem = json['mucMem'] as int?
      ..cap = json['cap'] as int?
      ..jug = json['jug'] as int?
      ..hydr = json['hydr'] as int?
      ..gut = json['gut'] as int?
      ..sore = json['sore'] as int?
      ..wounds = json['wounds'] as int?
      ..gait = json['gait'] as int?
      ..attitude = json['attitude'] as int?;

Map<String, dynamic> _$VetDataToJson(VetData instance) => <String, dynamic>{
      'passed': instance.passed,
      'hr1': instance.hr1,
      'hr2': instance.hr2,
      'resp': instance.resp,
      'mucMem': instance.mucMem,
      'cap': instance.cap,
      'jug': instance.jug,
      'hydr': instance.hydr,
      'gut': instance.gut,
      'sore': instance.sore,
      'wounds': instance.wounds,
      'gait': instance.gait,
      'attitude': instance.attitude,
    };
