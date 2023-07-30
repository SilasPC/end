// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EventError.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
