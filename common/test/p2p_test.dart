
import 'dart:async';

import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/db.dart';
import 'package:test/test.dart';

void main() {

	test("something", () {

		var peerStream = StreamController<Peer>();
		var s = P2PManager(null, peerStream.stream, NullDatabase.create);
		var c = P2PManager(LocalPeer(s), Stream.empty(), NullDatabase.create);
		peerStream.add(LocalPeer(c));

	});

}
