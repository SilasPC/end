// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeerIdentity _$PeerIdentityFromJson(Map<String, dynamic> json) =>
    PeerIdentity.raw(
      const PublicKeyConverter().fromJson(json['key'] as String),
      json['name'] as String,
      PeerPermission.fromJson(json['perms'] as Map<String, dynamic>),
      const SignatureConverter().fromJson(json['signature'] as String),
      json['parent'] == null
          ? null
          : PeerIdentity.fromJson(json['parent'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PeerIdentityToJson(PeerIdentity instance) {
  final val = <String, dynamic>{
    'key': const PublicKeyConverter().toJson(instance.key),
    'signature': const SignatureConverter().toJson(instance.signature),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('parent', instance.parent);
  val['name'] = instance.name;
  val['perms'] = instance.perms;
  return val;
}

PreSyncMsg _$PreSyncMsgFromJson(Map<String, dynamic> json) => PreSyncMsg(
      json['identity'] == null
          ? null
          : PeerIdentity.fromJson(json['identity'] as Map<String, dynamic>),
      json['session'] == null
          ? null
          : Session.fromJson(json['session'] as Map<String, dynamic>),
      json['resetCount'] as int,
      protocolVersion: json['protocolVersion'] as int? ?? SyncProtocol.VERSION,
    );

Map<String, dynamic> _$PreSyncMsgToJson(PreSyncMsg instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('identity', instance.identity);
  val['protocolVersion'] = instance.protocolVersion;
  writeNotNull('session', instance.session);
  val['resetCount'] = instance.resetCount;
  return val;
}
