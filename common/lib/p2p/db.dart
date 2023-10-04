
import 'dart:math';

import 'package:common/p2p/Manager.dart';
import '../util.dart';

abstract class EventDatabase<M extends IJSON> {
	Future<void> add(SyncMsg<M> sr);
	Future<void> clear({required bool keepPeers});
	Future<Tuple<SyncMsg<M>, PreSyncMsg?>> loadData();
	Future<Object?> loadPeer(String peerId);
}

class NullDatabase<M extends IJSON> extends EventDatabase<M> {

	@override
	Future<void> add(SyncMsg<M> msg) async {}
	@override
	Future<void> clear({required bool keepPeers}) async {}
	@override
	Future<Tuple<SyncMsg<M>, PreSyncMsg?>> loadData()
		=> Future.value(
				Tuple(
					SyncMsg([], []),
					null,
				)
		);

	@override
	Future<Object?> loadPeer(String peerId) async => null;
}
