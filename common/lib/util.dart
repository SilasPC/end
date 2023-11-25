
import 'dart:async';
import 'dart:convert';
export 'util/unix.dart';

typedef JSON = Map<String, dynamic>;
typedef Reviver<T> = T Function(JSON);
typedef Predicate<T> = bool Function(T);
typedef Producer<T> = T Function();
typedef AsyncProducer<T> = Producer<FutureOr<T>>;
typedef VoidCallback = void Function();

abstract class IJSON {
	const IJSON();
	JSON toJson();
	String toJsonString() => jsonEncode(toJson());
	List<int> toJsonBin() => toJsonString().codeUnits;
	static JSON fromBin(List<int> bin) =>
		jsonDecode(String.fromCharCodes(bin));
}

T? try_cast<T>(dynamic from) => from is T ? from : null;

T unimpl<T>([msg]) => throw UnimplementedError(msg);

P? maybe<T,P>(T? t, P? Function(T) f) =>
	t == null ? null : f(t);

/** Optionally map a dictionary key */
T? jmap<T>(JSON m, String k, T Function(JSON) f) {
	if (!m.containsKey(k)) return null;
	var v = m[k];
	if (v == null) return null;
	return f(v);
}

/** Revive elements using f */
List<T> jlist_map<T,P>(List<dynamic> json, T Function(P) f) =>
	json.map((e) => f(e as P)).toList();

/** Convert list to JSON */
List<dynamic> listj(List<IJSON> l) => l.map((e) => e.toJson()).toList();

/** Convert iterable to JSON */
List<dynamic> iterj(Iterable<IJSON> l) => l.map((e) => e.toJson()).toList();

T jsonClone<T extends IJSON>(T t, Reviver<T> f) => f(jsonDecode(jsonEncode(json)));

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
 * Return the index of the first element for which `p` is true.
 * `p` should thus return true for the tail of the list.
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
 * Return the index of the last element for which `p` is true.
 * `p` should thus return false for the tail of the list.
 */
int binarySearchLast<T>(List<T> list, bool Function(T) p) {
	if (list.isEmpty) return -1;
	int low = 0, hgh = list.length - 1;
	while (low < hgh) {
		int mid = ((low+hgh)/2).ceil();
		if (p(list[mid])) {
			low = mid;
		} else {
			hgh = mid - 1;
		}
	}
	return p(list[low]) ? low : -1;
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

/// Returns an index mapping `map`, such that the index of `list[i]`,
/// were it to be sorted, would be `map[i]`.
/// 
/// Thus the map provides the actual index the elements would recieve if sorted.
List<int> sortIndexMap<T>(List<T> list, Comparator<T> cmp) {
	var indices = List.generate(list.length, (index) => index)
		..sort((a, b) => cmp(list[a], list[b]));
	var map = List.filled(list.length, 0);
	for (int i = 0; i < list.length; i++) {
		map[indices[i]] = i;
	}
	return map;
}

Stream<T> futStream<T>(Iterable<Future<T>> ts) {
   var stream = StreamController<T>();
   int i = 1;
   for (var t in ts) {
      i++;
      t
         .then(
				(value) => stream.add(value),
				onError: (e) => stream.addError(e),
			)
         .whenComplete(() {
            if (--i == 0) {
               stream.close();
            } 
         });
   }
   if (--i == 0) {
		stream.close();
	} 
   return stream.stream;
}
