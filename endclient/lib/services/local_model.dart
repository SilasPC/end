
import 'dart:async';
import 'dart:io';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:common/p2p/protocol.dart';
import 'package:common/p2p/sqlite_db.dart';
import 'package:flutter/widgets.dart';

class LocalModel with ChangeNotifier {

	final MetaModel metaModel = MetaModel() ;

	late PeerManager<Model> _manager;

   StreamSubscription? _sub;

	LocalModel() {
		_manager = PeerManager(
			PrivatePeerIdentity.client(Platform.localHostname),
			SqliteDatabase.create,
			metaModel,
		);
		_sub = _manager.updateStream.listen((_) => notifyListeners());
	}

   @override
   void dispose() {
      _sub?.cancel();
      super.dispose();
   }

	String get id => _manager.id.name;

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []])
		=> _manager.add(evs, dels);

	Set<Event<Model>> get deletes => _manager.deletes;
	ReadOnlyOrderedSet<Event<Model>> get events => _manager.events;
	Model get model => _manager.model;

	void resetModel() => _manager.resetModel();

}
