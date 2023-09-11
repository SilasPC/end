
import 'package:common/EventModel.dart';
import 'package:common/event_model/EventModel.dart';
import 'package:common/event_model/SyncedEventModel.dart';
import 'package:common/util.dart';
import 'package:test/test.dart';

void main() {
	test("empty model", () {
		var s = ServerModel();
		var c = ClientModel(s);
		expect(s.model.result, "");
		expect(c.model.result, "");
	});
	test("one-client sync", (() async {
		var s = ServerModel();
		var c = ClientModel(s);

		s.add([StrEv("A", 10), StrEv("B", 20)]);
		c.add([       StrEv("X", 15)         ]);
		expect(s.model.result, "AB");
		expect(c.model.result, "X");

		await c.sync();
		expect(s.model.result, "AXB");
		expect(c.model.result, "AXB");
		expect(s.events.toString(), s.events.toString());
	}));
	test("two-client sync", () async {
		var s = ServerModel();
		var c1 = ClientModel(s);
		var c2 = ClientModel(s);

		s.add([StrEv("A", 10), StrEv("B", 20)]);
		await c2.sync();
		await c1.addSync([StrEv("X", 15), StrEv("Y", 25)]);
		expect(s.model.result,  "AXBY");
		expect(c1.model.result, "AXBY");
		expect(c2.model.result, "AB");

		c2.add([StrEv("1", 30)]);
		expect(c2.model.result, "AB1");

		await c2.sync();
		expect(s.model.result,  "AXBY1");
		expect(c2.model.result, "AXBY1");
		expect(c1.model.result, "AXBY");

		await c1.addSync([StrEv("Z", 23)]);
		expect(s.model.result,  "AXBZY1");
		expect(c1.model.result, "AXBZY1");

		await c2.sync();
		expect(c2.model.result, "AXBZY1");

		await c2.addSync([], [StrEv("X", 15)]);
		expect(c2.model.result, "ABZY1");
		expect(s.model.result, "ABZY1");

		await c1.sync();
		expect(c1.model.result, "ABZY1");
	});
	test("deletes", () {
		var m = ServerModel();

		m.add([StrEv("0",0)]);
		m.createSavepoint();

		m.add([StrEv("1",1)]);
		m.createSavepoint();

		expect(m.savepoints.length, 3);
		expect(m.model.result, "01");

		m.add([], [StrEv("1",1)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "0");
		
		m.add([], [StrEv("0",0)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "");
		
		m.add([StrEv("2",0)], [StrEv("2",0)]);
		expect(m.model.result, "");

	});
	test("set max time", () {
		var m = ServerModel();
		m.add([
			for (int i = 0; i < 5; i++)
			StrEv(i.toString(), i),
		]);
		m.createSavepoint();
		m.add([
			for (int i = 5; i < 10; i++)
			StrEv(i.toString(), i),
		]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "0123456789");

		m.setMaxTime(9);
		expect(m.model.result, "0123456789");
		m.setMaxTime(7);
		expect(m.model.result, "01234567");
		m.setMaxTime(8);
		expect(m.model.result, "012345678");
		m.setMaxTime(3);
		expect(m.model.result, "0123");
		m.setMaxTime(null);
		expect(m.model.result, "0123456789");
		m.setMaxTime(3);
		expect(m.model.result, "0123");
		m.setMaxTime(4);
		expect(m.model.result, "01234");
		m.setMaxTime(6);
		expect(m.model.result, "0123456");
		m.setMaxTime(-1);
		expect(m.model.result, "");
		m.setMaxTime(20);
		expect(m.model.result, "0123456789");

	});
	test("savepoints", () {
		var m = ServerModel();
		m.add([StrEv("0",0), StrEv("2",2)]);
		m.createSavepoint();
		expect(m.savepoints.length, 2);
		expect(m.model.result, "02");

		m.add([StrEv("4",4)]);
		m.createSavepoint();
		expect(m.savepoints.length, 3);
		expect(m.model.result, "024");

		m.add([StrEv("3",3)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "0234");
		
		m.add([StrEv("1",1)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "01234");

		m.add([StrEv("6",6)]);
		m.createSavepoint();
		m.add([StrEv("7",7)]);
		m.createSavepoint();
		expect(m.savepoints.length, 3);
		expect(m.model.result, "0123467");

		m.add([StrEv("5",5)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "01234567");

		m.createSavepoint();
		m.add([], [StrEv("3",3)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "0124567");
		
		m.createSavepoint();
		m.add([StrEv("8",8),StrEv("9",9)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "012456789");
		
		m.add([], [StrEv("8",8)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "01245679");
		
		m.add([], [StrEv("0",0)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "1245679");

	});
}

class StrEv extends Event<Model> {
	
	final String str;
	StrEv(this.str, int time): super(time, "kind", "author");

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

class ClientModel extends SyncedEventModel<Model> {
	ServerModel server;
	ClientModel(this.server): super(Handle(), (req) async => req.applyTo(server));
}

class ServerModel extends EventModel<Model> {
	ServerModel(): super(Handle());
}

class Handle extends EventModelHandle<Model> {
	Model revive(JSON json) => Model.fromJson(json);
	Model createModel() => Model();
}
