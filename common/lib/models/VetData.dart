
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

	List<VetFieldValue> remarks([bool returnHr = false]) =>
		[
			if (hr1 case int hr1)
				VetField.HR1.withValue(hr1),
			if (hr2 case int hr2)
				VetField.HR2.withValue(hr2),
			if (resp case int resp)
				VetField.RESP.withValue(resp),
			if (mucMem case int mucMem)
				VetField.MUC_MEM.withValue(mucMem),
			if (cap case int cap)
				VetField.CAP.withValue(cap),
			if (jug case int jug)
				VetField.JUG.withValue(jug),
			if (hydr case int hydr)
				VetField.HYDR.withValue(hydr),
			if (gut case int gut)
				VetField.GUT.withValue(gut),
			if (sore case int sore)
				VetField.SORE.withValue(sore),
			if (wounds case int wounds)
				VetField.WNDS.withValue(wounds),
			if (gait case int gait)
				VetField.GAIT.withValue(gait),
			if (attitude case int attitude)
				VetField.ATT.withValue(attitude),
		];

	JSON toJson() => _$VetDataToJson(this);
	factory VetData.fromJson(JSON json) =>
		_$VetDataFromJson(json);

}

// CHECK: what is letter vs. digit
enum VetField {
	
	HR1		(VetFieldType.NUMBER, "Pulse 1"),
	HR2		(VetFieldType.NUMBER, "Pulse 2"),
	RESP		(VetFieldType.LETTER, "Respiration"),
	MUC_MEM	(VetFieldType.DIGIT, "Mucous membranes"),
	CAP		(VetFieldType.DIGIT, "Capilary refill"),
	JUG		(VetFieldType.DIGIT, "Jugular refill"),
	HYDR		(VetFieldType.DIGIT, "Hydration"),
	GUT		(VetFieldType.LETTER, "Gut sounds"),
	SORE		(VetFieldType.LETTER, "Soreness"),
	WNDS		(VetFieldType.LETTER, "Wounds"),
	GAIT		(VetFieldType.LETTER, "Gait"),
	ATT		(VetFieldType.LETTER, "Attitude");

	const VetField(this.type, this.name);

	final VetFieldType type;
	final String name;

	VetFieldValue withValue(int value) => VetFieldValue(this, value);
	
}

enum VetFieldType {
	NUMBER,
	LETTER,
	DIGIT;
}

class VetFieldValue {

	final VetField field;
	final int value;
	
	const VetFieldValue(this.field, this.value);

	@override
	String toString() {
		switch (field.type) {
			case VetFieldType.DIGIT:
			case VetFieldType.NUMBER:
				return value.toString();
			case VetFieldType.LETTER:
				return String.fromCharCode(64 + value);
		}
	}

}
