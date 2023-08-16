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

Map<String, dynamic> _$VetDataToJson(VetData instance) {
  final val = <String, dynamic>{
    'passed': instance.passed,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('hr1', instance.hr1);
  writeNotNull('hr2', instance.hr2);
  writeNotNull('resp', instance.resp);
  writeNotNull('mucMem', instance.mucMem);
  writeNotNull('cap', instance.cap);
  writeNotNull('jug', instance.jug);
  writeNotNull('hydr', instance.hydr);
  writeNotNull('gut', instance.gut);
  writeNotNull('sore', instance.sore);
  writeNotNull('wounds', instance.wounds);
  writeNotNull('gait', instance.gait);
  writeNotNull('attitude', instance.attitude);
  return val;
}
