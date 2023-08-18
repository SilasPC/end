
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../util.dart';
import 'EventModel.dart';

part "Event.g.dart";

abstract class Event<M extends IJSON> extends IJSON with EquatableMixin implements Comparable<Event<M>> {
	final String kind;
	final int time;
	final String author;

	Event(this.time, this.kind, this.author);

	bool build(EventModel<M> m);

	int compareTo(Event<M> rhs) {
		int i = time - rhs.time;
		if (i == 0) i = kind.compareTo(rhs.kind);
		if (i == 0) i = author.compareTo(rhs.author);
		return i;
	}

}

@JsonSerializable()
class EventId extends IJSON implements Comparable<EventId> {

	final int time;
	final String author;

	EventId(this.time, this.author);
	factory EventId.of(Event ev) =>
		EventId(ev.time, ev.author);

	JSON toJson() => _$EventIdToJson(this);
	factory EventId.fromJson(JSON json) =>
		_$EventIdFromJson(json);

	@override
	String toString() => "$author:$time";

	@override
	int compareTo(EventId other) {
		int x = time - other.time;
		return x == 0 ? author.compareTo(other.author) : x;
	}

	@override
	int get hashCode => time + 31 * author.hashCode;

	@override
	operator ==(Object other) =>
		other is EventId &&
		other.time == time &&
		other.author == author;

}
