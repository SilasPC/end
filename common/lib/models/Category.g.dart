// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Loop _$LoopFromJson(Map<String, dynamic> json) => Loop(
      json['distance'] as int,
      json['restTime'] as int,
    );

Map<String, dynamic> _$LoopToJson(Loop instance) => <String, dynamic>{
      'distance': instance.distance,
      'restTime': instance.restTime,
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      json['equipeId'] as int?,
      json['name'] as String,
      (json['loops'] as List<dynamic>)
          .map((e) => Loop.fromJson(e as Map<String, dynamic>))
          .toList(),
      json['startTime'] as int,
    )
      ..equipages = (json['equipages'] as List<dynamic>)
          .map((e) => Equipage.fromJson(e as Map<String, dynamic>))
          .toList()
      ..clearRound = json['clearRound'] as bool
      ..minSpeed = json['minSpeed'] as int?
      ..maxSpeed = json['maxSpeed'] as int?
      ..idealSpeed = json['idealSpeed'] as int?;

Map<String, dynamic> _$CategoryToJson(Category instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('equipeId', instance.equipeId);
  val['name'] = instance.name;
  val['loops'] = instance.loops;
  val['equipages'] = instance.equipages;
  val['startTime'] = instance.startTime;
  val['clearRound'] = instance.clearRound;
  writeNotNull('minSpeed', instance.minSpeed);
  writeNotNull('maxSpeed', instance.maxSpeed);
  writeNotNull('idealSpeed', instance.idealSpeed);
  return val;
}
