
import 'package:json_annotation/json_annotation.dart';
import '../util.dart';

part "EventError.g.dart";

@JsonSerializable()
class EventError extends IJSON {

   EventError(this.causedBy, this.description);

   /// The event index of the cause.
   int causedBy;
   String description;

	JSON toJson() => _$EventErrorToJson(this);
	factory EventError.fromJson(JSON json) =>
		_$EventErrorFromJson(json);

}
