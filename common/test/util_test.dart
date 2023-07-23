
import 'package:common/util.dart';
import 'package:test/test.dart';

void main() {
	group("binarySearch", () {
		List<int> list = [0,1,2,3,4,5,6,7];
		test("empty", () {
			int i = binarySearch([], (_) => throw "unreachable");
			expect(i, -1);
		});
		test("single element", () {
			int i = binarySearch([0], (_) => true);
			expect(i, 0);
			i = binarySearch([0], (_) => false);
			expect(i, -1);
		});
		test("is correct", () {
			int i = binarySearch(list, (n) => n >= 4);
			expect(i, 4);
		});
		test("all false", () {
			int i = binarySearch(list, (n) => n >= 9);
			expect(i, -1);
		});
		test("all true", () {
			int i = binarySearch(list, (n) => n >= 0);
			expect(i, 0);
		});
	});
	test("unix convertions", () {
		int unix = 22503698173;
		var dt = fromUNIX(unix);
		expect(toUNIX(dt), unix);
		var hms = "12:16:13";
		expect(toHMS(dt), hms);
		expect(unixHMS(unix), hms);
		var unixx = hmsToUNIX(hms); // this is a date today
		expect(unixHMS(unixx), hms);
	});
	group("reorder", () {
		var lst = () => [0,1,2,3];
		test("no reorder", () {
			expect(reorder(0, 0, lst()), lst());
			expect(reorder(3, 3, lst()), lst());
		});
		test("forwards", () {
			// todo: not sure how this is supposed to work anyways
			//expect(reorder(0, 1, lst()), [1,0,2,3]);
			//expect(reorder(0, 4, lst()), [1,2,3,0]);
		});
		test("backwards", () {
			expect(reorder(1, 0, lst()), [1,0,2,3]);
			expect(reorder(3, 0, lst()), [3,0,1,2]);
		});
	});
}
