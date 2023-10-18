
import 'package:common/EventModel.dart';
import 'package:test/test.dart';
import 'str.dart';

void main() {
	var dig = StrEv.dig;
	test("empty model", () {
		var s = Model();
		expect(s.model.result, "");
	});
	test("deletes", () {
		var m = Model();

		m.add([dig(0)]);
		m.createSavepoint();

		m.add([dig(1)]);
		m.createSavepoint();

		expect(m.savepoints.length, 3);
		expect(m.model.result, "01");

		m.add([], [dig(1)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "0");
		
		m.add([], [dig(0)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "");
		
		m.add([dig(2)], [dig(2)]);
		expect(m.model.result, "");

	});
	test("set max time", () {
		var m = Model();
		m.add([
			for (int i = 0; i < 5; i++)
			dig(i),
		]);
		m.createSavepoint();
		m.add([
			for (int i = 5; i < 10; i++)
			dig(i),
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
		var m = Model();
		m.add([dig(0), dig(2)]);
		m.createSavepoint();
		expect(m.savepoints.length, 2);
		expect(m.model.result, "02");

		m.add([dig(4)]);
		m.createSavepoint();
		expect(m.savepoints.length, 3);
		expect(m.model.result, "024");

		m.add([dig(3)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "0234");
		
		m.add([dig(1)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "01234");

		m.add([dig(6)]);
		m.createSavepoint();
		m.add([dig(7)]);
		m.createSavepoint();
		expect(m.savepoints.length, 3);
		expect(m.model.result, "0123467");

		m.add([dig(5)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "01234567");

		m.createSavepoint();
		m.add([], [dig(3)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "0124567");
		
		m.createSavepoint();
		m.add([dig(8),dig(9)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "012456789");
		
		m.add([], [dig(8)]);
		expect(m.savepoints.length, 2);
		expect(m.model.result, "01245679");
		
		m.add([], [dig(0)]);
		expect(m.savepoints.length, 1);
		expect(m.model.result, "1245679");

	});
}

class Model extends EventModel<StrModel> {
	Model(): super(StrHandle());
}
