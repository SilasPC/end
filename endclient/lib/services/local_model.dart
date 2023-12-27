import 'dart:async';
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:common/p2p/Manager.dart';
import 'package:flutter/widgets.dart';

class LocalModel with ChangeNotifier {
  final MetaModel metaModel = MetaModel();

  late final PeerManager<EnduranceModel> _manager;

  StreamSubscription? _sub;

  LocalModel(this._manager) {
    _sub = _manager.updateStream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addSync(List<Event<EnduranceModel>> evs,
          [List<Event<EnduranceModel>> dels = const []]) =>
      _manager.add(evs, dels);

  Set<Event<EnduranceModel>> get deletes => _manager.deletes;
  ReadOnlyOrderedSet<Event<EnduranceModel>> get events => _manager.events;
  EnduranceModel get model => _manager.model;

  void resetModel() => _manager.resetModel();
}
