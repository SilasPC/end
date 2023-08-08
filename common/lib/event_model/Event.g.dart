// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Event.dart';

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
