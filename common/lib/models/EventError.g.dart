// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EventError.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventError _$EventErrorFromJson(Map<String, dynamic> json) => EventError(
      json['description'] as String,
      EventId.fromJson(json['causedBy'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EventErrorToJson(EventError instance) =>
    <String, dynamic>{
      'description': instance.description,
      'causedBy': instance.causedBy,
    };
