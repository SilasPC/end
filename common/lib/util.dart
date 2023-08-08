
import 'dart:convert';

typedef JSON = Map<String, dynamic>;

typedef Predicate<T> = bool Function(T);

abstract class IJSON {
	JSON toJson();
	String toJsonString() => jsonEncode(toJson());
}

T unimpl<T>([msg]) => throw UnimplementedError(msg);

P? maybe<T,P>(T? t, P? Function(T) f) =>
	t == null ? null : f(t);

const UNIX_FUTURE = 32503676400; // year 3000

String toHMS(DateTime t) => t.toIso8601String().substring(11,19);
int toUNIX(DateTime t) => (t.millisecondsSinceEpoch / 1000).floor();
String unixHMS(int unix) => toHMS(fromUNIX(unix));
DateTime fromUNIX(int unix) =>
	DateTime.fromMillisecondsSinceEpoch(unix * 1000);
int nowUNIX() => toUNIX(DateTime.now());
int hmsToUNIX(String hms) {
	var dt = DateTime.now();
	var midnight = toUNIX(dt) - dt.hour * 3600 - dt.minute * 60 - dt.second;
	List<int> hms0 = hms.split(":").map(int.parse).toList();
	return midnight + 3600 * hms0[0] + 60 * hms0[1] + hms0[2];
}
DateTime fromHMS(int h, int m, int s) {
	var dt = DateTime.now();
	var midnight = toUNIX(dt) - dt.hour * 3600 - dt.minute * 60 - dt.second;
	return fromUNIX(midnight + 3600 * h + 60 * m + s);
}
String unixDifToMS(int dif, [bool addPlus = false]) {
	int m = (dif.abs() / 60).floor();
	int s = dif % 60;
	String ms = m > 9 ? "$m" : "0$m";
	String ss = s > 9 ? "$s" : "0$s";
	return dif < 0 ? "-$ms:$ss" : (addPlus ? "+$ms:$ss" : "$ms:$ss" );
}

/** Optionally map a dictionary key */
T? jmap<T>(JSON m, String k, T Function(JSON) f) {
	if (!m.containsKey(k)) return null;
	var v = m[k];
	if (v == null) return null;
	return f(v);
}

/*JSON mapj<K,IJSON>(Map<K,IJSON> m) =>
	m.map((K key, IJSON value) => MapEntry(key.toString(), value.toJSON()));*/

/** Revive elements using f */
List<T> jlist_map<T,P>(List<dynamic> json, T Function(P) f) =>
	json.map((e) => f(e as P)).toList();

/** Revive elements by casting */
List<T> jlist_cast<T>(List<dynamic> json) => jlist_map(json, (e) => e as T);

/** Convert list to JSON */
List<dynamic> listj(List<IJSON> l) => l.map((e) => e.toJson()).toList();


class Tuple<A,B> {
	final A a;
	final B b;
	Tuple(this.a,this.b);
  @override
  String toString() => "Tuple($a, $b)";
}

class Tuple3<A,B,C> {
  final A a;
  final B b;
  final C c;
  Tuple3(this.a,this.b,this.c);
  @override
  String toString() => "Tuple3($a, $b, $c)";
}

/**
 * Find the index of the first element where the predicate is true.
 * This assummes that the predicate partitions the list, such that
 * the first part is assigned false.
 * Returns -1 if no elements match the predicate.
 */
int binarySearch<T>(List<T> list, bool Function(T) p) {
	if (list.isEmpty) return -1;
	int low = 0, hgh = list.length - 1;
	while (low < hgh) {
		int mid = ((low+hgh)/2).floor();
		if (p(list[mid])) {
			hgh = mid;
		} else {
			low = mid + 1;
		}
	}
	return p(list[low]) ? low : -1;
}

/**
 * Like `binarySearch`, but returns the index of the first element
 * not matching the predicate.
*/
// todo: not tested, probably incorrect on all true
int binarySearchInv<T>(List<T> list, bool Function(T) p) {
	int i = binarySearch(list, p);
	if (i == -1) return 0; // all false
	return i - 1;
}

List<T> reorder<T>(int i, int j, List<T> lst) {
	if (j > i) j--;
	return lst..insert(j, lst.removeAt(i));
}

List<T> swap<T>(int i, int j, List<T> lst) {
	var e = lst[i];
	lst[i] = lst[j];
	lst[j] = e;
	return lst;
}
