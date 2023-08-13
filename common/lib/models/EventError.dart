
// todo: not unique id
import 'package:json_annotation/json_annotation.dart';

import '../EnduranceEvent.dart';
import '../event_model/Event.dart';
import '../util.dart';

part "EventError.g.dart";

// todo: make enum of errors
@JsonSerializable()
class EventError extends IJSON {

   EventError(this.description, this.causedBy);
   EventError.of(this.description, EnduranceEvent ev):
		this.causedBy = EventId(ev.time, ev.author);

   String description;
   EventId causedBy;

	JSON toJson() => _$EventErrorToJson(this);
	factory EventError.fromJson(JSON json) =>
		_$EventErrorFromJson(json);

}
