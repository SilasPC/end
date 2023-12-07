
import 'package:common/p2p/Manager.dart';
import '../event_model/EventModel.dart';
import '../util.dart';

abstract class EventDatabase<M extends IJSON> {
	Future<void> add(SyncMsg<M> sr);
	Future<void> clear({required bool keepPeers});
	Future<(SyncMsg<M>, PreSyncMsg?)> loadData(String peerId);
	Future<(PreSyncMsg, SyncInfo)?> loadPeer(String peerId);
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
	Future<(SyncMsg<M>, PreSyncMsg?)> loadData(String peerId)
		=> Future.value(
				(
					SyncMsg<M>([], []),
					PreSyncMsg(
						peerId,
						sessionId,
						0
					),
				)
			);

	@override
	Future<(PreSyncMsg, SyncInfo)?> loadPeer(String peerId) async => null;

	@override
	Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo) async {}

}
