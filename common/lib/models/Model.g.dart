// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnduranceModel _$EnduranceModelFromJson(Map<String, dynamic> json) =>
    EnduranceModel()
      ..rideName = json['rideName'] as String
      ..equipeId = json['equipeId'] as int?
      ..categories = (json['categories'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Category.fromJson(e as Map<String, dynamic>)),
      )
      ..errors = (json['errors'] as List<dynamic>)
          .map((e) => EventError.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$EnduranceModelToJson(EnduranceModel instance) {
  final val = <String, dynamic>{
    'rideName': instance.rideName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('equipeId', instance.equipeId);
  val['categories'] = instance.categories;
  val['errors'] = instance.errors;
  return val;
}
