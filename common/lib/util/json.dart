
import 'dart:convert';

typedef JSON = Map<String, dynamic>;
typedef Reviver<T> = T Function(JSON);

abstract mixin class JsonMixin {
	JSON toJson();
	String toJsonString() => jsonEncode(toJson());
	List<int> toJsonBin() => toJsonString().codeUnits;
}

abstract class IJSON with JsonMixin {
	const IJSON();
	static JSON fromBin(List<int> bin) =>
		jsonDecode(String.fromCharCodes(bin));
}

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
