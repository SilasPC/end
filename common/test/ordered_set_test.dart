
import 'package:common/event_model/OrderedSet.dart';
import 'package:test/test.dart';

void main() {
	test("integers", () {
		var s = OrderedSet<int>.withComparator(((a, b) => a-b));
		s.addAll([2,3,4,1,0,5,6]);
		expect(s.findOrdIndex(4), 4);
		expect(s.byInsertionIndex(3), 1);
	});
}
