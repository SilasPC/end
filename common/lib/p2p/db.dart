import 'package:common/p2p/protocol.dart';
import '../event_model/EventModel.dart';
import '../util.dart';

abstract class EventDatabase<M extends IJSON> {
  Future<void> add(SyncMsg<M> sr);
  Future<void> clear({required bool keepPeers});

  Future<(PreSyncMsg, SyncInfo)?> loadPeer(String peerId);
  Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo);

  Future<(SyncMsg<M>, PreSyncMsg?)> loadData();
  Future<void> saveData(PreSyncMsg state);
}

class NullDatabase<M extends IJSON> extends EventDatabase<M> {
  final String peerId;
  final Session? session;

  NullDatabase(this.peerId, this.session);

  @override
  Future<void> add(SyncMsg<M> msg) async {}
  @override
  Future<void> clear({required bool keepPeers}) async {}
  @override
  Future<(SyncMsg<M>, PreSyncMsg?)> loadData() => Future.value((
        SyncMsg<M>([], [], [], [], []),
        PreSyncMsg(null, session, 0),
      ));

  @override
  Future<(PreSyncMsg, SyncInfo)?> loadPeer(String peerId) async => null;

  @override
  Future<void> savePeer(PreSyncMsg state, SyncInfo syncInfo) async {}

  @override
  Future<void> saveData(PreSyncMsg state) async {}
}
