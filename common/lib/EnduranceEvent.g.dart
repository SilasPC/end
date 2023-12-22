// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'EnduranceEvent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitEvent _$InitEventFromJson(Map<String, dynamic> json) => InitEvent(
      json['author'] as String,
      json['time'] as int,
      EnduranceModel.fromJson(json['model'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InitEventToJson(InitEvent instance) => <String, dynamic>{
      'author': instance.author,
      'time': instance.time,
      'type': instance.type,
      'model': instance.model,
    };

DisqualifyEvent _$DisqualifyEventFromJson(Map<String, dynamic> json) =>
    DisqualifyEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
      json['reason'] as String,
    );

Map<String, dynamic> _$DisqualifyEventToJson(DisqualifyEvent instance) =>
    <String, dynamic>{
      'author': instance.author,
      'time': instance.time,
      'type': instance.type,
      'eid': instance.eid,
      'reason': instance.reason,
    };

ChangeCategoryEvent _$ChangeCategoryEventFromJson(Map<String, dynamic> json) =>
    ChangeCategoryEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
      json['category'] as String,
    );

Map<String, dynamic> _$ChangeCategoryEventToJson(
        ChangeCategoryEvent instance) =>
    <String, dynamic>{
      'author': instance.author,
      'time': instance.time,
      'type': instance.type,
      'eid': instance.eid,
      'category': instance.category,
    };

RetireEvent _$RetireEventFromJson(Map<String, dynamic> json) => RetireEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
    );

Map<String, dynamic> _$RetireEventToJson(RetireEvent instance) =>
    <String, dynamic>{
      'author': instance.author,
      'time': instance.time,
      'type': instance.type,
      'eid': instance.eid,
    };

ExamEvent _$ExamEventFromJson(Map<String, dynamic> json) => ExamEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
      VetData.fromJson(json['data'] as Map<String, dynamic>),
      json['loopHint'] as int?,
    );

Map<String, dynamic> _$ExamEventToJson(ExamEvent instance) {
  final val = <String, dynamic>{
    'author': instance.author,
    'time': instance.time,
    'type': instance.type,
    'eid': instance.eid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('loopHint', instance.loopHint);
  val['data'] = instance.data;
  return val;
}

VetEvent _$VetEventFromJson(Map<String, dynamic> json) => VetEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
      json['loopHint'] as int?,
    );

Map<String, dynamic> _$VetEventToJson(VetEvent instance) {
  final val = <String, dynamic>{
    'author': instance.author,
    'time': instance.time,
    'type': instance.type,
    'eid': instance.eid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('loopHint', instance.loopHint);
  return val;
}

ArrivalEvent _$ArrivalEventFromJson(Map<String, dynamic> json) => ArrivalEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
      json['loopHint'] as int?,
    );

Map<String, dynamic> _$ArrivalEventToJson(ArrivalEvent instance) {
  final val = <String, dynamic>{
    'author': instance.author,
    'time': instance.time,
    'type': instance.type,
    'eid': instance.eid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('loopHint', instance.loopHint);
  return val;
}

StartClearanceEvent _$StartClearanceEventFromJson(Map<String, dynamic> json) =>
    StartClearanceEvent(
      json['author'] as String,
      json['time'] as int,
      (json['eids'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$StartClearanceEventToJson(
        StartClearanceEvent instance) =>
    <String, dynamic>{
      'author': instance.author,
      'time': instance.time,
      'type': instance.type,
      'eids': instance.eids,
    };

DepartureEvent _$DepartureEventFromJson(Map<String, dynamic> json) =>
    DepartureEvent(
      json['author'] as String,
      json['time'] as int,
      json['eid'] as int,
      json['loopHint'] as int?,
    );

Map<String, dynamic> _$DepartureEventToJson(DepartureEvent instance) {
  final val = <String, dynamic>{
    'author': instance.author,
    'time': instance.time,
    'type': instance.type,
    'eid': instance.eid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('loopHint', instance.loopHint);
  return val;
}
