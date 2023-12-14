// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protocol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivatePeerIdentity _$PrivatePeerIdentityFromJson(Map<String, dynamic> json) =>
    PrivatePeerIdentity(
      const PrivateKeyConverter()
          .fromJson(json['privateKey'] as String),
      PeerIdentity.fromJson(json['identity'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PrivatePeerIdentityToJson(
        PrivatePeerIdentity instance) =>
    <String, dynamic>{
      'privateKey': const PrivateKeyConverter().toJson(instance.privateKey),
      'identity': instance.identity,
    };

PeerIdentity _$PeerIdentityFromJson(Map<String, dynamic> json) => PeerIdentity(
      const PublicKeyConverter().fromJson(json['key'] as String),
      const SignatureConverter().fromJson(json['signature'] as String),
      json['name'] as String,
    );

Map<String, dynamic> _$PeerIdentityToJson(PeerIdentity instance) =>
    <String, dynamic>{
      'key': const PublicKeyConverter().toJson(instance.key),
      'signature': const SignatureConverter().toJson(instance.signature),
      'name': instance.name,
    };

PreSyncMsg _$PreSyncMsgFromJson(Map<String, dynamic> json) => PreSyncMsg(
      PeerIdentity.fromJson(json['identity'] as Map<String, dynamic>),
      json['sessionId'] as int,
      json['resetCount'] as int,
      protocolVersion: json['protocolVersion'] as int? ?? SyncProtocol.VERSION,
    );

Map<String, dynamic> _$PreSyncMsgToJson(PreSyncMsg instance) =>
    <String, dynamic>{
      'identity': instance.identity,
      'protocolVersion': instance.protocolVersion,
      'sessionId': instance.sessionId,
      'resetCount': instance.resetCount,
    };
