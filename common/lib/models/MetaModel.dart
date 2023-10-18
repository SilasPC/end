
import 'package:common/EnduranceEvent.dart';
import 'package:common/event_model/Event.dart';
import 'package:common/event_model/EventModel.dart';
import 'package:common/models/Model.dart';
import 'package:common/util.dart';

import 'EventError.dart';

class MetaModel extends EventModelHandle<Model> {

	// TODO: not entirely correct
	Set<int> _accepted = {};

   bool isAccepted(EventError e) => _accepted.contains(e.causedBy);

	Iterable<EventError> get unaccepted
		=> model.model.errors.where((e) => !_accepted.contains(e.causedBy))
			.followedBy(
				model.model.warnings.where((e) => !_accepted.contains(e.causedBy))
			);

	void accept(EventError error) {
		_accepted.add(error.causedBy);
	}

	@override
	void didReset() {
		_accepted.clear();
	}

	@override
	Model createModel() => Model();

	@override
	Model revive(JSON json) => Model.fromJson(json);

	@override
	Event<Model> reviveEvent(JSON json) => EnduranceEvent.fromJson(json);
}