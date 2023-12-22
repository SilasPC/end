import 'package:common/p2p/keys.dart';
import 'package:common/p2p/protocol.dart';
import 'package:test/test.dart';

void main() {
  // TEST: p2p crypto behaviour

  test("verifySignature works", () {
    var fakeSelfSigned = PrivatePeerIdentity(
        clientPrivKey,
        PeerIdentity.signed("client", clientPubKey, PeerPermission.all,
            clientPrivKey.createSigner(SIGNING_ALG)));
    var client = PrivatePeerIdentity.client("client");
    expect(client.identity.verifySignature(serverPubKey), true);
    expect(fakeSelfSigned.identity.verifySignature(serverPubKey), false);
  });

  test("PeerIdentity equality", () {
    var c = PeerIdentity.client("c");
    expect(c, c);
    expect(c, PeerIdentity.client("c"));
    var a = PeerIdentity.anonymous();
    expect(a, a);
    expect(c, isNot(a));
  });

  test("PrivatePeerIdentity equality", () {
    var c = PrivatePeerIdentity.client("c");
    expect(c, c);
    expect(c, PrivatePeerIdentity.client("c"));
    var a = PrivatePeerIdentity.anonymous();
    expect(a, a);
    expect(c, isNot(a));
  });
}
