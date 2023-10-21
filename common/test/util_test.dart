
import 'dart:math';

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
			int j = binarySearchLast(list, (n) => n < 4);
			expect(j, 3);
		});
		test("all false", () {
			int i = binarySearch(list, (_) => false);
			expect(i, -1);
			int j = binarySearchLast(list, (_) => false);
			expect(j, -1);
		});
		test("all true", () {
			int i = binarySearch(list, (_) => true);
			expect(i, 0);
			int j = binarySearchLast(list, (_) => true);
			expect(j, list.length - 1);
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
			// not entirely sure about the reasoning
			// here, but it works with the reordering
			// for Flutter lists
			expect(reorder(0, 0, lst()), [0,1,2,3]);
			expect(reorder(0, 1, lst()), [0,1,2,3]);
			expect(reorder(0, 2, lst()), [1,0,2,3]);
			expect(reorder(0, 4, lst()), [1,2,3,0]);
		});
		test("backwards", () {
			expect(reorder(1, 0, lst()), [1,0,2,3]);
			expect(reorder(3, 0, lst()), [3,0,1,2]);
		});
	
	
	});
	
	test("futStream", () async {
		var ns = List.generate(5, (n) => n);
		var futs = ns.map((n) => Future.delayed(Duration(milliseconds: n * 50), () => n)).toList();
		futs.shuffle(Random(0));
		futs.insert(0, Future.error("An error"));
		futs.add(Future.error("Another error"));

		var output = <int>[];
		var caught = 0;
		await for (var n in futStream(futs).handleError((_) => caught++)) {
			output.add(n);
		}

		expect(caught, 2);
		expect(output, [0,1,2,3,4]);
	});

}
