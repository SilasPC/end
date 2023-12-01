
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
			if (hr1 case int hr1 when returnHr)
				VetField.HR1.withValue(hr1),
			if (hr2 case int hr2 when returnHr)
				VetField.HR2.withValue(hr2),
			if (resp case int resp when resp != 1)
				VetField.RESP.withValue(resp),
			if (mucMem case int mucMem when mucMem != 1)
				VetField.MUC_MEM.withValue(mucMem),
			if (cap case int cap when cap != 1)
				VetField.CAP.withValue(cap),
			if (jug case int jug when jug != 1)
				VetField.JUG.withValue(jug),
			if (hydr case int hydr when hydr != 1)
				VetField.HYDR.withValue(hydr),
			if (gut case int gut when gut != 1)
				VetField.GUT.withValue(gut),
			if (sore case int sore when sore != 1)
				VetField.SORE.withValue(sore),
			if (wounds case int wounds when wounds != 1)
				VetField.WNDS.withValue(wounds),
			if (gait case int gait when gait != 1)
				VetField.GAIT.withValue(gait),
			if (attitude case int attitude when attitude != 1)
				VetField.ATT.withValue(attitude),
		];

	JSON toJson() => _$VetDataToJson(this);
	factory VetData.fromJson(JSON json) =>
		_$VetDataFromJson(json);

}

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
