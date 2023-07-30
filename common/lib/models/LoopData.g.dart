// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LoopData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
