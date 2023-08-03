// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Category.dart';

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
      json['startTime'] as int,
    )..equipages = (json['equipages'] as List<dynamic>)
        .map((e) => Equipage.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      'name': instance.name,
      'loops': instance.loops,
      'equipages': instance.equipages,
      'startTime': instance.startTime,
    };
