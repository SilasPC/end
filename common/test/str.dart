
import 'package:common/EventModel.dart';
import 'package:common/util.dart';

class StrEv extends Event<StrModel> {
	
	final String str;
	StrEv(this.str, int time): super(time, "kind", "author");
	factory StrEv.dig(int dig) {
		assert(dig >= 0, "Digit must be non-negative");
		String str = dig.toRadixString(36);
		assert(str.length == 1, "Digit must be in range 0..36");
		return StrEv(str, dig);
	}

	@override
	JSON toJson() => {
		"time": time,
		"char": str
	};

	factory StrEv.fromJson(JSON json) =>
		StrEv(json['char'], json['time']);

	@override
	String toString() => "[$time;$str]";

	@override
	bool build(EventModel<StrModel> m) {
		m.model.result += str;
		return true;
	}

	@override
	List get props => [time, str];

}

class StrModel extends IJSON {
	String result = "";

	@override
	JSON toJson() => {
		"result": result
	};
	
	StrModel();
	StrModel.fromJson(JSON json):
		result = json["result"];

	@override
	String toString() => result;
	
}

class StrHandle extends EventModelHandle<StrModel> {
	StrModel revive(JSON json) => StrModel.fromJson(json);
	StrEv reviveEvent(JSON json) => StrEv.fromJson(json);
	StrModel createModel() => StrModel();
}
