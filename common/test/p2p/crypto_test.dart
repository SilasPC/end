import 'package:common/p2p/keys.dart';
import 'package:common/p2p/protocol.dart';
import 'package:test/test.dart';

void main() {
  // TEST: p2p crypto behaviour

  /* test("verifySignature works", () {
    var fakeSelfSigned = PrivatePeerIdentity.root(
        clientPrivKey,
		  clientPubKey,
		  "malicious",
	 );
    expect(client.identity.verifySignature(serverPubKey), true);
    expect(fakeSelfSigned.identity.verifySignature(serverPubKey), false);
  }); */

  /* test("PeerIdentity equality", () {
    var c = PeerIdentity.client("c");
    expect(c, c);
    expect(c, PeerIdentity.client("c"));
    var c2 = PeerIdentity.client("c2");
    expect(c2, c2);
    expect(c, isNot(c2));
  });

  test("PrivatePeerIdentity equality", () {
    var c = PrivatePeerIdentity.client("c");
    expect(c, c);
    expect(c, PrivatePeerIdentity.client("c"));
    var c2 = PrivatePeerIdentity.client("c2");
    expect(c2, c2);
    expect(c, isNot(c2));
  }); */
}
