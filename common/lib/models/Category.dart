
import 'package:json_annotation/json_annotation.dart';

import '../util.dart';
import 'glob.dart';

part "Category.g.dart";

@JsonSerializable()
class Loop extends IJSON {
	int distance;
	int restTime;
	Loop(this.distance, this.restTime);
	JSON toJson() => _$LoopToJson(this);
	factory Loop.fromJson(JSON json) =>
		_$LoopFromJson(json);
}

@JsonSerializable()
class Category extends IJSON {
	String name;
	List<Loop> loops;
	List<Equipage> equipages;
	int startTime;
	Category(this.name, this.loops, this.startTime) :
		equipages = [];

	int numDNF() =>
		equipages.where((e) => e.isOut).length;

	int numFinished() =>
		equipages.where((e) => e.isFinished).length;

	int numEnded() =>
		equipages.where((e) => e.isEnded).length;

	bool isEnded() => numEnded() == equipages.length;

	int distance() {
		int dist = 0;
		for (var l in loops)
			dist += l.distance;
		return dist;
	}

	JSON toJson() => _$CategoryToJson(this);
	factory Category.fromJson(JSON json) =>
		_$CategoryFromJson(json);
	
}
