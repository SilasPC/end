import 'package:common/EnduranceEvent.dart';
import 'package:common/event_model/Event.dart';
import 'package:common/event_model/EventModel.dart';
import 'package:common/models/Model.dart';
import 'package:common/util.dart';

import 'EventError.dart';

class MetaModel extends EventModelHandle<EnduranceModel> {
  // TODO: not entirely correct
  Set<int> _accepted = {};

  bool isAccepted(EventError e) => _accepted.contains(e.causedBy);

  Iterable<EventError> get unaccepted =>
      model.model.errors.where((e) => !_accepted.contains(e.causedBy));

  void accept(EventError error) {
    _accepted.add(error.causedBy);
  }

  @override
  void didReset() {
    _accepted.clear();
  }

  @override
  EnduranceModel createModel() => EnduranceModel();

  @override
  EnduranceModel revive(JSON json) => EnduranceModel.fromJson(json);

  @override
  Event<EnduranceModel> reviveEvent(JSON json) => EnduranceEvent.fromJson(json);
}
