import 'dart:typed_data';

import 'package:common/p2p/keys.dart';
import 'package:common/p2p/protocol.dart';
import 'package:common/util.dart';
import 'package:test/test.dart';

void main() {
  // TEST: p2p crypto behaviour

  test("verifySignature works", () {
    var fakeSelfSigned = PrivatePeerIdentity(
        clientPrivKey,
        PeerIdentity.signed("client", clientPubKey, PeerPermission.all,
            clientPrivKey.createSigner(SIGNING_ALG)));
    var client = PrivatePeerIdentity.client("client");
    assert(client.identity.verifySignature(serverPubKey));
    assert(!fakeSelfSigned.identity.verifySignature(serverPubKey));
  });

  test("json converters", () {
    var pkc = PublicKeyConverter();

    var key = pkc.fromJson(pkc.toJson(serverPubKey));
    assert(key.exponent == serverPubKey.exponent &&
        key.modulus == serverPubKey.modulus);

    var kc = PrivateKeyConverter();

    var key2 = kc.fromJson(kc.toJson(serverPrivKey));
    assert(key2.firstPrimeFactor == serverPrivKey.firstPrimeFactor &&
        key2.secondPrimeFactor == serverPrivKey.secondPrimeFactor &&
        key2.privateExponent == serverPrivKey.privateExponent &&
        key2.modulus == serverPrivKey.modulus);

    var data = Uint8List.fromList("I am a piece of data for signing".codeUnits);
    var sign = serverPrivKey.createSigner(SIGNING_ALG).sign(data);

    var sc = SignatureConverter();

    var sign2 = sc.fromJson(sc.toJson(sign));
    assert(listEq(sign.data, sign2.data));
  });
}
