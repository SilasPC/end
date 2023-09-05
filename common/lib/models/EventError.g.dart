// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EventError.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventError _$EventErrorFromJson(Map<String, dynamic> json) => EventError(
      json['causedBy'] as int,
      json['description'] as String,
    );

Map<String, dynamic> _$EventErrorToJson(EventError instance) =>
    <String, dynamic>{
      'causedBy': instance.causedBy,
      'description': instance.description,
    };
