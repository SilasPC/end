import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/p2p/protocol.dart';
import 'package:test/test.dart';

import '../str.dart';

void main() {
  var manager = (String id, int sessionId) => PeerManager<StrModel>(
        PrivatePeerIdentity.client(id),
        () => NullDatabase<StrModel>(
            id, Session(sessionId, PrivatePeerIdentity.server().identity)),
        StrHandle(),
      )..autoConnect = true;

  test("self identity", () {
    var c = manager("c", 1);
    expect(c.id!.verifySignature(), true);
  });

  test("pre sync", () async {
    var (ps, pc) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 1);

    await c.addPeer(ps);
    await s.addPeer(pc);
    await pumpEventQueue();

    expect(ps.state, PeerState.SYNC);
    expect(pc.state, PeerState.SYNC);
  });

  test("pre sync conflict", () async {
    var (ps, pc) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 2);

    await c.addPeer(ps);
    await s.addPeer(pc);
    await pumpEventQueue();

    expect(ps.state, PeerState.CONFLICT);
    expect(pc.state, PeerState.CONFLICT);
  });

  test("two way simple", () async {
    var (p1, p2) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 1);

    await s.add([StrEv.dig(1, "s")]);

    await c.addPeer(p1);
    await s.addPeer(p2);
    await pumpEventQueue();

    expect(s.model.result, "1");
    expect(c.model.result, "1");

    await s.add([StrEv.dig(2, "s")]);
    await pumpEventQueue();
    expect(s.model.result, "12");
    expect(c.model.result, "12");

    await c.add([StrEv.dig(3, "c")]);
    await pumpEventQueue();
    expect(s.model.result, "123");
    expect(c.model.result, "123");

    await c.add([], [StrEv.dig(2, "c")]);
    await pumpEventQueue();
    expect(s.model.result, "13");
    expect(c.model.result, "13");
  });

  test("three way indirect", () async {
    var con1 = LocalPeer.pair();
    var con2 = LocalPeer.pair();
    var p1 = manager("p1", 1);
    var p2 = manager("p2", 1);
    var p3 = manager("p3", 1);

    await p2.addPeer(con1.$1);
    await p1.addPeer(con1.$2);
    await p3.addPeer(con2.$1);
    await p2.addPeer(con2.$2);
    await pumpEventQueue();

    await p1.add([StrEv.dig(1, "p1")]);
    await pumpEventQueue();
    expect(p1.model.result, "1");
    expect(p2.model.result, "1");
    expect(p3.model.result, "1");
  });

  test("two way reset", () async {
    var (ps, pc) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 1);

    await c.addPeer(ps);
    await s.addPeer(pc);

    await s.add([StrEv.dig(1, "s")]);
    await pumpEventQueue();
    expect(s.model.result, "1");
    expect(c.model.result, "1");

    await c.resetModel();
    expect(c.model.result, "");
    await pumpEventQueue();
    expect(c.model.result, "1");
  });

  test("conflict", () async {
    var (ps, pc) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 2);

    await c.addPeer(ps);
    await s.addPeer(pc);

    await s.add([StrEv.dig(1, "s")]);
    await pumpEventQueue();
    expect(s.model.result, "1");
    expect(c.model.result, "");

    var yielded = await c.yieldTo(ps);
    expect(yielded, true);
    expect(c.session!.eq(s.session!), true);

    await pumpEventQueue();
    expect(c.model.result, "1");
  });

  test("change identity", () async {
    var (ps, pc) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 2);

    await c.addPeer(ps);
    await s.addPeer(pc);

    await pumpEventQueue();

    c.changeIdentity(PrivatePeerIdentity.client("c2"));
    await pumpEventQueue();
    expect(pc.id, "c2");
  });

  test("leave session", () async {
    var (ps, pc) = LocalPeer.pair();
    var s = manager("s", 1);
    var c = manager("c", 1);

    await c.addPeer(ps);
    await s.addPeer(pc);

    await pumpEventQueue();
    expect(pc.state, PeerState.SYNC);

    c.leaveSession();
    await pumpEventQueue();
    expect(pc.state, PeerState.NOSESS);
  });
}
