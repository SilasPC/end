
import 'package:equatable/equatable.dart';
import '../util.dart';
import 'EventModel.dart';

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
