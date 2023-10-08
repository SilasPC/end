
import 'package:common/p2p/Manager.dart';
import '../event_model/EventModel.dart';
import '../util.dart';

abstract class EventDatabase<M extends IJSON> {
	Future<void> add(SyncMsg<M> sr);
	Future<void> clear({required bool keepPeers});
	Future<Tuple<SyncMsg<M>, PreSyncMsg?>> loadData(String peerId);
	Future<Tuple<PreSyncMsg, SyncInfo>?> loadPeer(String peerId);
	Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo);
}

class NullDatabase<M extends IJSON> extends EventDatabase<M> {

	final String peerId;
	final int sessionId;

	NullDatabase(this.peerId, this.sessionId);

	@override
	Future<void> add(SyncMsg<M> msg) async {}
	@override
	Future<void> clear({required bool keepPeers}) async {}
	@override
	Future<Tuple<SyncMsg<M>, PreSyncMsg?>> loadData(String peerId)
		=> Future.value(
				Tuple(
					SyncMsg([], []),
					PreSyncMsg(
						peerId,
						sessionId,
						0
					),
				)
		);

	@override
	Future<Tuple<PreSyncMsg, SyncInfo>?> loadPeer(String peerId) async => null;

	@override
	Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo) async {}

}
