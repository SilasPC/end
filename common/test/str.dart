
import 'package:common/EventModel.dart';
import 'package:common/util.dart';

class StrEv extends Event<Model> {
	
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

	@override
	String toString() => "[$time;$str]";

	@override
	bool build(EventModel<Model> m) {
		m.model.result += str;
		return true;
	}

	@override
	List get props => [time, str];

}

class Model extends IJSON {
	String result = "";

	@override
	JSON toJson() => {
		"result": result
	};
	
	Model();
	Model.fromJson(JSON json):
		result = json["result"];

	@override
	String toString() => result;
	
}

class Handle extends EventModelHandle<Model> {
	Model revive(JSON json) => Model.fromJson(json);
	Model createModel() => Model();
}
