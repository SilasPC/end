
// todo: not unique id
import 'package:json_annotation/json_annotation.dart';

import '../EnduranceEvent.dart';
import '../util.dart';

part "EventError.g.dart";

@JsonSerializable()
class EventId extends IJSON {

	EventId(this.time, this.author);
	EventId.of(EnduranceEvent ev):
		time = ev.time,
		author = ev.author;

	final int time;
	final String author;

	String toString() => "$author:$time";

	JSON toJson() => _$EventIdToJson(this);
	factory EventId.fromJson(JSON json) =>
		_$EventIdFromJson(json);

}

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
