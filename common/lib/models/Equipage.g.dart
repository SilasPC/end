// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Equipage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
