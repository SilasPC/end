
import 'package:json_annotation/json_annotation.dart';

import '../util.dart';
import 'glob.dart';

part "Category.g.dart";

@JsonSerializable()
class Loop extends IJSON {
	/// kilometers
   int distance;
   /// minutes
	int restTime;
	Loop(this.distance, this.restTime);
	JSON toJson() => _$LoopToJson(this);
	factory Loop.fromJson(JSON json) =>
		_$LoopFromJson(json);
}

@JsonSerializable()
class Category extends IJSON {
	int? equipeId;
	String name;
	List<Loop> loops;
	List<Equipage> equipages;
	int startTime;
	bool clearRound = false;

	/// km/h
	int? minSpeed, maxSpeed, idealSpeed;

	Category(this.equipeId, this.name, this.loops, this.startTime) :
		equipages = [];

	int numDNF() =>
		equipages.where((e) => e.isOut).length;

	int numFinished() =>
		equipages.where((e) => e.isFinished).length;

	int numEnded() =>
		equipages.where((e) => e.isEnded).length;

	bool isEnded() => numEnded() == equipages.length;
	
	int? minRideTime() => minSpeed == null ? null : (3600 * distance() / minSpeed!).floor();
	int? maxRideTime() => maxSpeed == null ? null : (3600 * distance() / maxSpeed!).floor();

	int totalRestTime() {
		int time = 0;
		for (var l in loops.getRange(0, loops.length-1))
			time += l.restTime;
		return time;
	}

	int distance() {
		int dist = 0;
		for (var l in loops)
			dist += l.distance;
		return dist;
	}

	JSON toJson() => _$CategoryToJson(this);
	factory Category.fromJson(JSON json) {
		var self = _$CategoryFromJson(json);
      self.equipages.sort(Equipage.byEid);
      return self;
   }
	
}
