import 'package:common/AbstractEventModel.dart';
import 'package:common/AbstractEventModelWithRemoteSync.dart';
import 'package:common/util.dart';
import 'package:test/test.dart';

void main() {
	test("empty model", () {
		var s = ServerModel.withBase(Model());
		var c = ClientModel.withBase(s, Model(), []);
		expect(s.model.result, "");
		expect(c.model.result, "");
	});
	test("one-client sync", (() async {
		var s = ServerModel.withBase(Model());
		var c = ClientModel.withBase(s, Model(), []);

		s.addEvents([StrEv("A", 10), StrEv("B", 20)]);
		c.addNoSync([       StrEv("X", 15)         ]);
		expect(s.model.result, "AB");
		expect(c.model.result, "X");

		await c.syncRemote();
		expect(s.model.result, "AXB");
		expect(c.model.result, "AXB");
		expect(s.events.toString(), s.events.toString());
	}));
	test("two-client sync", () async {
		var s = ServerModel.withBase(Model());
		var c1 = ClientModel.withBase(s, Model(), []);
		var c2 = ClientModel.withBase(s, Model(), []);

		s.addEvents([StrEv("A", 10), StrEv("B", 20)]);
		await c2.syncRemote();
		await c1.addAndSync([StrEv("X", 15), StrEv("Y", 25)]);
		expect(s.model.result,  "AXBY");
		expect(c1.model.result, "AXBY");
		expect(c2.model.result, "AB");

		c2.addNoSync([StrEv("1", 30)]);
		expect(c2.model.result, "AB1");

		await c2.syncRemote();
		expect(s.model.result,  "AXBY1");
		expect(c2.model.result, "AXBY1");
		expect(c1.model.result, "AXBY");

		await c1.addAndSync([StrEv("Z", 23)]);
		expect(s.model.result,  "AXBZY1");
		expect(c1.model.result, "AXBZY1");

		await c2.syncRemote();
		expect(c2.model.result, "AXBZY1");

		await c2.appendAndSync([], [EvId(15)]);
		expect(c2.model.result, "ABZY1");
		expect(s.model.result, "ABZY1");

		await c1.syncRemote();
		expect(c1.model.result, "ABZY1");
	});
	test("savepoints", () {
		var m = ServerModel.withBase(Model());
		m.append([StrEv("0",0), StrEv("2",2)]);
		m.createSavepoint();
		expect(m.savepoints.length, 2);
		expect(m.model.result, "02");

		m.append([StrEv("4",4)]);
		m.createSavepoint();
		expect(m.savepoints.length, 3);
		expect(m.model.result, "024");

		m.append([StrEv("3",3)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "0234");
		
		m.append([StrEv("1",1)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "01234");

		m.append([StrEv("6",6)]);
		m.createSavepoint();
		m.append([StrEv("7",7)]);
		m.createSavepoint();
		expect(m.savepoints.length, 3);
		expect(m.model.result, "0123467");

		m.append([StrEv("5",5)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "01234567");
	});
}

class EvId extends EventId {
	EvId(int time): super(time, "author");
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
  bool build(AbstractEventModel<Model> m) {
	  m.model.result += str;
	  return true;
  }

}

class Model extends IJSON {
	String result = "";

	@override
	JSON toJson() => {
		"result": result
	};
	
	Model();
	Model.fromJSON(JSON json):
		result = json["result"];

	@override
	String toString() => result;
	
}

class ClientModel extends AbstractEventModelWithRemoteSync<Model> {

	ServerModel server;
	ClientModel.withBase(this.server, super.model, super.events);

	@override
	Model $reviveModel(JSON json) => Model.fromJSON(json);

	@override
	Future<SyncResult<Model>> $doRemoteSync(SyncRequest<Model> a) async =>
		server.syncFromRequest(a);

	@override
	String toString() => "$gen, $events, $model";

	@override
	void $onUpdate() {}

}

class ServerModel extends AbstractEventModel<Model> {

	ServerModel.withBase(Model m) : super.withBase(m);

	@override
	Model $reviveModel(JSON json) => Model.fromJSON(json);

	@override
	String toString() => "$gen, $events, $model";

	@override
	void $onUpdate() {}

}
