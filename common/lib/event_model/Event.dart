
import 'package:equatable/equatable.dart';
import '../util.dart';
import 'EventModel.dart';

abstract interface class Event<M extends IJSON> extends IJSON with EquatableMixin implements Comparable<Event<M>> {
	int get time;
	void build(EventModel<M> m);
	int compareTo(Event<M> rhs);
}
