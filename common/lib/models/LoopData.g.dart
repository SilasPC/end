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

Map<String, dynamic> _$LoopDataToJson(LoopData instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('expDeparture', instance.expDeparture);
  writeNotNull('departure', instance.departure);
  writeNotNull('arrival', instance.arrival);
  writeNotNull('vet', instance.vet);
  writeNotNull('data', instance.data);
  return val;
}
