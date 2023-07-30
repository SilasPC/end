// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VetData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
