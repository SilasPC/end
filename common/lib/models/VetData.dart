
import 'package:json_annotation/json_annotation.dart';

import '../util.dart';

part "VetData.g.dart";

@JsonSerializable()
class VetData extends IJSON {

	bool passed;
	int? hr1, hr2, resp, mucMem, cap, jug, hydr, gut, sore, wounds, gait, attitude;
	VetData(this.passed);

	VetData.empty() : this.passed = false;
	VetData.passed() : this.passed = true;

	VetData clone() => VetData.fromJson(toJson());

	JSON toJson() => _$VetDataToJson(this);
	factory VetData.fromJson(JSON json) =>
		_$VetDataFromJson(json);

}
