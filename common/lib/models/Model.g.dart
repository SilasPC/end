// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Model _$ModelFromJson(Map<String, dynamic> json) => Model()
  ..rideName = json['rideName'] as String
  ..categories = (json['categories'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, Category.fromJson(e as Map<String, dynamic>)),
  )
  ..errors = (json['errors'] as List<dynamic>)
      .map((e) => EventError.fromJson(e as Map<String, dynamic>))
      .toList()
  ..warnings = (json['warnings'] as List<dynamic>)
      .map((e) => EventError.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$ModelToJson(Model instance) => <String, dynamic>{
      'rideName': instance.rideName,
      'categories': instance.categories,
      'errors': instance.errors,
      'warnings': instance.warnings,
    };
