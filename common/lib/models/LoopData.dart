
import 'package:json_annotation/json_annotation.dart';

import '../util.dart';
import 'glob.dart';

part "LoopData.g.dart";

@JsonSerializable(constructor: "raw")
class LoopData extends IJSON {

	int? expDeparture;
	int? departure;
	int? arrival;
	int? vet;
	VetData? data;

	@JsonKey(ignore: true)
	late Loop loop;

	LoopData(this.loop);
	LoopData.raw();

	double? speed({bool finish = false}) {
		int? t = finish ? timeToArrival : timeToVet;
		if (t == null) return null;
		return loop.distance * 3600 / t;
	}

	int? get recoveryTime =>
		arrival != null && vet != null ? vet! - arrival! : null;

	int? get timeToVet =>
		expDeparture != null && vet != null ? vet! - expDeparture! : null;
		
	int? get timeToArrival =>
		expDeparture != null && arrival != null ? arrival! - expDeparture! : null;
	
	JSON toJson() => _$LoopDataToJson(this);
	factory LoopData.fromJson(JSON json) =>
		_$LoopDataFromJson(json);

}
