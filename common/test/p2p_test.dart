
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/p2p/msg_encoder.dart';
import 'package:common/p2p/protocol.dart';
import 'package:test/test.dart';

import 'str.dart';

void main() {

	var manager = (String id, int sessionId) => PeerManager<StrModel>(
		PrivatePeerIdentity.server(id),
		() => NullDatabase<StrModel>(id, sessionId),
      StrHandle(),
	)..autoConnect = true;

	test("msg encoder", () {

		final raw = encodeMsg(
			0xdeadbeef,
			"deadbeef",
			[42],
		);
		
		expect(raw, [
			239, 190, 173, 222,
			0, 
			100, 101, 97, 100, 98, 101, 101, 102,
			0,
			42
		]);

		final (
			seq,
			msg,
			data,
			reply
		) = decodeMsg(raw);

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

		expect(raw, [
			190, 186, 254, 202,
			1,
			0
		]);

		final (
			seq,
			msg,
			data,
			reply
		) = decodeMsg(raw);
		
		expect(seq.toRadixString(16), "cafebabe");
		expect(msg, "");
		expect(data, [0]);
		expect(reply, true);

	});

	test("two way simple", () async {

		var (p1, p2) = LocalPeer.pair();
		var c1 = manager("server", 1);
		var c2 = manager("client", 1);
		
		await c1.add([StrEv.dig(1)]);
		expect(c1.model.result, "1");
		expect(c2.model.result, "");

		await c2.addPeer(p1);
		await c1.addPeer(p2);
		await pumpEventQueue();

		expect(c2.sessionId, c1.sessionId);
		expect(c2.sessionId, 1);
		expect(p1.state, PeerState.SYNC);
		expect(p2.state, PeerState.SYNC);

		expect(c1.model.result, "1");
		expect(c2.model.result, "1");

		await c1.add([StrEv.dig(2)]);
		await pumpEventQueue();
		expect(c1.model.result, "12");
		expect(c2.model.result, "12");
		
		await c2.add([StrEv.dig(3)]);
		await pumpEventQueue();
		expect(c1.model.result, "123");
		expect(c2.model.result, "123");

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

		await p1.add([StrEv.dig(1)]);
		await pumpEventQueue();
		expect(p1.model.result, "1");
		expect(p2.model.result, "1");
		expect(p3.model.result, "1");

		await p2.add([StrEv.dig(2)]);
		await pumpEventQueue();
		expect(p1.model.result, "12");
		expect(p2.model.result, "12");
		expect(p3.model.result, "12");

		await p3.add([StrEv.dig(3)]);
		await pumpEventQueue();
		expect(p1.model.result, "123");
		expect(p2.model.result, "123");
		expect(p3.model.result, "123");

	});

	test("two way reset", () async {

		var (p1, p2) = LocalPeer.pair();
		var s = manager("server", 1);
		var c = manager("client", 1);

		await c.addPeer(p1);
		await s.addPeer(p2);

		await s.add([StrEv.dig(1)]);
		await pumpEventQueue();
		expect(s.model.result, "1");
		expect(c.model.result, "1");

		await c.resetModel();
		expect(c.model.result, "");
		await pumpEventQueue();
		expect(c.model.result, "1");
		
	});

	test("conflict", () async {

		var (p1, p2) = LocalPeer.pair();
		var s = manager("server", 1);
		var c = manager("client", 2);

		await c.addPeer(p1);
		await s.addPeer(p2);

		await s.add([StrEv.dig(1)]);
		await pumpEventQueue();
		expect(s.model.result, "1");
		expect(c.model.result, "");

		var yielded = await c.yieldTo(p1);
		expect(yielded, true);
		expect(c.sessionId, s.sessionId);

		await pumpEventQueue();
		expect(c.model.result, "1");
		
	});

}
