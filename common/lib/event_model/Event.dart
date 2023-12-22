import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../util.dart';
import 'EventModel.dart';

abstract class Event<M extends IJSON> extends IJSON
    with EquatableMixin
    implements Comparable<Event<M>> {
  final String author;
  final int time;
  @JsonKey(includeToJson: true, includeFromJson: false)
  String get type => runtimeType.toString();

  const Event(this.author, this.time);

  void build(EventModel<M> m);

  int compareTo(Event<M> rhs) {
    int i = time - rhs.time;
    if (i == 0) i = runtimeType.hashCode - runtimeType.hashCode;
    if (i == 0) i = hashCode - rhs.hashCode;
    return i;
  }
}
