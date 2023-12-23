import 'package:common/event_model/OrderedSet.dart';
import 'package:test/test.dart';

void main() {
  test("integers", () {
    var s = OrderedSet<int>.withComparator(((a, b) => a - b));
    s.addAll([2, 3, 4, 1, 0, 5, 1, 6]);
    expect(s.ordIndexOf(4), 4);
    expect(s.indexIns(3), 1);
    expect(s.add(0), false);
    expect(s.add(-1), true);
    expect(s.ordIndexOf(-1), 0);
    expect(s.ordIndexOf(4), 5);
  });
}
