import 'dart:typed_data';

import 'package:common/EventModel.dart';
import 'package:common/p2p/keys.dart';
import 'package:common/util.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:json_annotation/json_annotation.dart';

part "protocol.g.dart";

final AlgorithmIdentifier SIGNING_ALG = algorithms.signing.rsa.sha256;

abstract class SyncProtocol {
  /// Current version of the protocol
  static const int VERSION = 1;

  /// SyncMsg payload
  static const String SYNC = "sync";

  /// PreSyncMsg payload
  static const String PRE_SYNC = "presync";

  /// no payload
  static const String ACK_SYNC = "syncack";

  static const List<int> OK = const [1];
  static const List<int> NOT_OK = const [0];

  static Iterable<String> get events => [SYNC, PRE_SYNC, ACK_SYNC];
}

class PrivatePeerIdentity {
  final RsaPrivateKey privateKey;
  final PeerIdentity identity;
  Signer<PrivateKey> get signer => privateKey.createSigner(SIGNING_ALG);

  PrivatePeerIdentity(this.privateKey, this.identity);

  factory PrivatePeerIdentity.root(
      PrivKey privateKey, PubKey key, String name, PeerPermission perms) {
    var id = PeerIdentity._unsigned(key, name, perms);
    id.signature = privateKey.createSigner(SIGNING_ALG).sign(id._signingData);
    id.parent = null;
    return PrivatePeerIdentity(privateKey, id);
  }

  // TODO: should not be available
  factory PrivatePeerIdentity.server() => PrivatePeerIdentity.root(
      serverPrivKey, serverPubKey, "eSys", PeerPermission.all);

  // TODO: should not be available
  factory PrivatePeerIdentity.client(String name) => PrivatePeerIdentity(
      clientPrivKey,
      PeerIdentity.signedBy(
        clientPubKey,
        name,
        PeerPermission.all,
        PrivatePeerIdentity.server(),
      ));

  bool operator ==(Object rhs) => switch (rhs) {
        PrivatePeerIdentity rhs => identity == rhs.identity &&
            PrivateKeyConverter().toJson(privateKey) ==
                PrivateKeyConverter().toJson(rhs.privateKey),
        _ => false
      };
}

// TODO: name is not id, key is
// VULN: perm subset, signing perm
@JsonSerializable(constructor: "raw")
class PeerIdentity extends IJSON {
  @PublicKeyConverter()
  final RsaPublicKey key;
  @SignatureConverter()
  late final Signature signature;
  late final PeerIdentity? parent;
  final String name;
  final PeerPermission perms;

  PeerIdentity get signer => parent ?? this;

  Verifier<PublicKey> get verifier => key.createVerifier(SIGNING_ALG);

  PeerIdentity._unsigned(this.key, this.name, this.perms);
  PeerIdentity.raw(
      this.key, this.name, this.perms, this.signature, this.parent);

  PeerIdentity.signedBy(
      this.key, this.name, this.perms, PrivatePeerIdentity id) {
    signature = id.signer.sign(_signingData);
    parent = id.identity;
  }

  bool verifySignature() {
    if (!signer.verifier.verify(_signingData, signature)) return false;
    return isRoot ? true : signer.verifySignature();
  }

  bool get isRoot => signer == this;
  PeerIdentity root() => signer == this ? this : signer.root();

  bool isSignedBy(PeerIdentity id) {
    if (id.isSame(id)) return true;
    return isRoot ? false : signer.isSignedBy(id);
  }

  JSON toJson() => _$PeerIdentityToJson(this);
  factory PeerIdentity.fromJson(JSON json) => _$PeerIdentityFromJson(json);

  Uint8List get _signingData => Uint16List.fromList([
        // IGNORED: TODO: proper signature instead of this trash
        ...PublicKeyConverter().toJson(key).codeUnits,
        ...":".codeUnits,
        ...perms.toJsonBin(),
        ...":".codeUnits,
        ...name.codeUnits,
      ]).buffer.asUint8List();

  bool isSame(PeerIdentity other) => listEq(_signingData, other._signingData);

  bool operator ==(Object rhs) => switch (rhs) {
        PeerIdentity rhs => toJsonString() == rhs.toJsonString(),
        _ => false
      };

  @override
  String toString() => "PeerIdentity($name)";
}

// IGNORED: TODO: permissions are not really p2p specific
class PeerPermission extends IJSON {
  static const PeerPermission none = PeerPermission(false, false);
  static const PeerPermission all = PeerPermission(true, true);

  // VULN: use permissions
  final bool admin;
  final bool serverAdmin;

  const PeerPermission(this.admin, this.serverAdmin);
  factory PeerPermission.fromJson(JSON json) =>
      PeerPermission(json["admin"], json["serverAdmin"]);

  @override
  JSON toJson() => {
        "admin": admin,
        "serverAdmin": serverAdmin,
      };
}

@JsonSerializable()
class PreSyncMsg extends IJSON {
  final PeerIdentity? identity;
  final int protocolVersion;
  final int sessionId;
  final int resetCount;

  const PreSyncMsg(this.identity, this.sessionId, this.resetCount,
      {this.protocolVersion = SyncProtocol.VERSION});

  JSON toJson() => _$PreSyncMsgToJson(this);

  factory PreSyncMsg.fromBin(List<int> bin) =>
      PreSyncMsg.fromJson(IJSON.fromBin(bin));
  factory PreSyncMsg.fromJson(JSON json) => _$PreSyncMsgFromJson(json);
}

class SyncMsg<M extends IJSON> extends IJSON {
  final List<Event<M>> evs, dels; // VULN: dels unsigned
  final List<Signature> sigs;
  final List<PeerIdentity> authors;

  SyncMsg(this.evs, this.dels, this.sigs, this.authors);

  JSON toJson() => {
        "evs": evs,
        "dels": dels,
        "sigs": sigs.map(SignatureConverter().toJson).toList(),
        "authors": listj(authors),
      };

  bool get isEmpty => evs.isEmpty && dels.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory SyncMsg.fromBin(List<int> bin, Reviver<Event<M>> reviver) =>
      SyncMsg.fromJson(IJSON.fromBin(bin), reviver);
  factory SyncMsg.fromJson(JSON json, Reviver<Event<M>> reviver) => SyncMsg(
        jlist_map(json["evs"], reviver),
        jlist_map(json["dels"], reviver),
        jlist_map(
            json["sigs"], (s) => SignatureConverter().fromJson(s as String)),
        jlist_map(json["authors"], PeerIdentity.fromJson),
      );
}
