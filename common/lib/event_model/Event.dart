
import 'package:equatable/equatable.dart';
import '../util.dart';
import 'EventModel.dart';

abstract class Event<M extends IJSON> extends IJSON with EquatableMixin implements Comparable<Event<M>> {
	
	final String author;
	final int time;
	
	const Event(this.time, this.author);

	void build(EventModel<M> m);
	
	int compareTo(Event<M> rhs)  {
		int i = time - rhs.time;
		if (i == 0) i = runtimeType.hashCode - runtimeType.hashCode;
		if (i == 0) i = hashCode - rhs.hashCode;
		return i;
	}

}
