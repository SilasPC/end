import 'dart:typed_data';

import 'package:common/p2p/keys.dart';
import 'package:common/p2p/msg_encoder.dart';
import 'package:common/p2p/protocol.dart';
import 'package:test/test.dart';

void main() {
  test("msg encoder", () {
    final raw = encodeMsg(
      0xdeadbeef,
      "deadbeef",
      [42],
    );

    expect(raw,
        [239, 190, 173, 222, 0, 100, 101, 97, 100, 98, 101, 101, 102, 0, 42]);

    final (seq, msg, data, reply) = decodeMsg(raw);

    expect(seq.toRadixString(16), "deadbeef");
    expect(msg, "deadbeef");
    expect(data, [42]);
    expect(reply, false);
  });

  test("msg reply encoder", () {
    final raw = encodeReply(
      0xcafebabe,
      [0],
    );

    expect(raw, [190, 186, 254, 202, 1, 0]);

    final (seq, msg, data, reply) = decodeMsg(raw);

    expect(seq.toRadixString(16), "cafebabe");
    expect(msg, "");
    expect(data, [0]);
    expect(reply, true);
  });
  test("json converters", () {
    var pkc = PublicKeyConverter();

    var key = pkc.fromJson(pkc.toJson(serverPubKey));
    expect(key.exponent, serverPubKey.exponent);
    expect(key.modulus, serverPubKey.modulus);

    var kc = PrivateKeyConverter();

    var key2 = kc.fromJson(kc.toJson(serverPrivKey));
    expect(key2.firstPrimeFactor, serverPrivKey.firstPrimeFactor);
    expect(key2.secondPrimeFactor, serverPrivKey.secondPrimeFactor);
    expect(key2.privateExponent, serverPrivKey.privateExponent);
    expect(key2.modulus, serverPrivKey.modulus);

    var data = Uint8List.fromList("I am a piece of data for signing".codeUnits);
    var sign = serverPrivKey.createSigner(SIGNING_ALG).sign(data);

    var sc = SignatureConverter();

    var sign2 = sc.fromJson(sc.toJson(sign));
    expect(sign.data, sign2.data);
  });
}
