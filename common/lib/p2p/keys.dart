import 'dart:convert';
import 'dart:typed_data';
import 'package:common/p2p/protocol.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:json_annotation/json_annotation.dart';

// note: these are just temporary pre-production keys from https://mkjwk.org/

final KeyPair _serverKeys = KeyPair.fromJwk({
  "p": "wAMhniqgnbe43C667yr5eGuJDQl3081U1aHrpt51z1E",
  "kty": "RSA",
  "q": "q0u2TUJy_x_s6lzYBOGHj9IKhoAIPsbHhvDQyhYPiD0",
  "d":
      "K50K42EHutmFwUsqDhR5NXZ8OS_qLKKkLYAjj6THeXx05ElrBZ5GWNTylErIYTFklj3a89Bsw8-WJT0JB6EHQQ",
  "e": "AQAB",
  "qi": "nHs7crF94i8LlE-6NUNvW1IMKevCE7V95jdNGQXtJag",
  "dp": "Ef35H3YFGOJHSzKBx7lyKOuCqxsRBGLAKUiD6V39EhE",
  "dq": "CiTUqeSafMM-O26-GCPm7DxrBSYF1vncjQArzRvbVZ0",
  "n":
      "gHrhG6x-ZLO_uveyIkBc6HzB0q-1Bo6VS6-xMkdbeTuXnn_npAD1inX6wYkKt7pklNQz65SJ-ssWAluTs_RuTQ"
});

final RsaPublicKey serverPubKey = _serverKeys.publicKey as RsaPublicKey;
final RsaPrivateKey serverPrivKey = _serverKeys.privateKey as RsaPrivateKey;
final Signer<PrivateKey> serverSigner = serverPrivKey.createSigner(SIGNING_ALG);

KeyPair _clientKeys = KeyPair.fromJwk({
  "p": "2NwftaFtWPuowKfS3mgcSKPqA0vYpS0T2gQLC0KDdpU",
  "kty": "RSA",
  "q": "x3lTZ5jihWCf1FMCJbfLyIc4QPd3-xzwToGMrV3YKds",
  "d":
      "YagqEDq2L-AzL9kdH8EuFttpx2nDv5Jbx8G5ip77FLgFhAU661PecM6Z8ulfBSb4zN0mWyXaspcsOPFbCzN3oQ",
  "e": "AQAB",
  "qi": "vRFyhnGUv1MaTPyAX7b3KvZg3No7jN0gZcE9rnxIb34",
  "dp": "LwRit519OLqvVr3MIT5PS4yGUxqhqQZB9JXF0zYjjJU",
  "dq": "Il9QtPBOUEdnIzIuk4tJTUOnuOIrxZSmABEoyZL7NbM",
  "n":
      "qPnjWE2wiGkilC8hLbSqDdo1YynYbc5G9Ke80aMyxVVDMkt_9yynNmL8wKyHpI57_Ci_-tV90l6Oqb_6IyxOdw"
});

final RsaPublicKey clientPubKey = _clientKeys.publicKey as RsaPublicKey;
final RsaPrivateKey clientPrivKey = _clientKeys.privateKey as RsaPrivateKey;

class PublicKeyConverter extends JsonConverter<RsaPublicKey, String> {
  const PublicKeyConverter();

  @override
  RsaPublicKey fromJson(String json) {
    var [exp, mod] = _parseBigInts(json);
    return RsaPublicKey(exponent: exp, modulus: mod);
  }

  @override
  String toJson(RsaPublicKey object) =>
      jsonEncode([object.exponent.toString(), object.modulus.toString()]);
}

class SignatureConverter extends JsonConverter<Signature, String> {
  const SignatureConverter();

  @override
  Signature fromJson(String json) =>
      Signature(Uint8List.fromList((jsonDecode(json) as List).cast<int>()));

  @override
  String toJson(Signature object) => jsonEncode(object.data);
}

class PrivateKeyConverter extends JsonConverter<RsaPrivateKey, String> {
  const PrivateKeyConverter();

  @override
  RsaPrivateKey fromJson(String json) {
    var [p, q, e, n] = _parseBigInts(json);
    return RsaPrivateKey(
      firstPrimeFactor: p,
      secondPrimeFactor: q,
      privateExponent: e,
      modulus: n,
    );
  }

  @override
  String toJson(RsaPrivateKey object) => jsonEncode([
        object.firstPrimeFactor.toString(),
        object.secondPrimeFactor.toString(),
        object.privateExponent.toString(),
        object.modulus.toString(),
      ]);
}

List<BigInt> _parseBigInts(String json) =>
    (jsonDecode(json) as List).map((s) => BigInt.parse(s as String)).toList();
