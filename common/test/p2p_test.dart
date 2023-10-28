
import 'dart:async';

import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:common/p2p/msg_encoder.dart';
import 'package:test/test.dart';

import 'str.dart';

void main() {

	var manager = (String id, int sessionId) => PeerManager<StrModel>(
		id,
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

	test("two way", () async {

		var pair = LocalPeer.pair();
		var s = manager("server", 1);
		var c = manager("client", 1);
		
		await s.add([StrEv.dig(1)]);
		expect(s.model.result, "1");
		expect(c.model.result, "");

		await c.addPeer(pair.a);
		await s.addPeer(pair.b);
		await pumpEventQueue();

		expect(c.sessionId, s.sessionId);
		expect(c.sessionId, 1);
		expect(pair.a.state.isSync, true);
		expect(pair.b.state.isSync, true);

		expect(s.model.result, "1");
		expect(c.model.result, "1");

		await s.add([StrEv.dig(2)]);
		await pumpEventQueue();
		expect(s.model.result, "12");
		expect(c.model.result, "12");
		
		await c.add([StrEv.dig(3)]);
		await pumpEventQueue();
		expect(s.model.result, "123");
		expect(c.model.result, "123");

	});

	test("three way indirect", () async {

		var con1 = LocalPeer.pair();
		var con2 = LocalPeer.pair();
		var p1 = manager("p1", 1);
		var p2 = manager("p2", 1);
		var p3 = manager("p3", 1);
		
		await p2.addPeer(con1.a);
		await p1.addPeer(con1.b);
		await p3.addPeer(con2.a);
		await p2.addPeer(con2.b);
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

		var pair = LocalPeer.pair();
		var s = manager("server", 1);
		var c = manager("client", 1);

		await c.addPeer(pair.a);
		await s.addPeer(pair.b);

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

		var pair = LocalPeer.pair();
		var s = manager("server", 1);
		var c = manager("client", 2);

		await c.addPeer(pair.a);
		await s.addPeer(pair.b);

		await s.add([StrEv.dig(1)]);
		await pumpEventQueue();
		expect(s.model.result, "1");
		expect(c.model.result, "");

		var yielded = await c.yieldTo(pair.a);
		expect(yielded, true);
		expect(c.sessionId, s.sessionId);

		await pumpEventQueue();
		expect(c.model.result, "1");
		
	});

}
