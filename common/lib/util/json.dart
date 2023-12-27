import 'dart:convert';
import 'dart:typed_data';

typedef JSON = Map<String, dynamic>;
typedef Reviver<T> = T Function(JSON);

abstract mixin class JsonMixin {
  JSON toJson();
  String toJsonString() => jsonEncode(toJson());
  List<int> toJsonBin() => toJsonString().codeUnits;
  Uint8List toJsonBytes() =>
      Uint16List.fromList(toJsonBin()).buffer.asUint8List();
}

abstract class IJSON with JsonMixin {
  const IJSON();
  static JSON fromBin(List<int> bin) => jsonDecode(String.fromCharCodes(bin));
  static List<int> toBin(JSON json) => jsonEncode(json).codeUnits;
  static T clone<T extends IJSON>(T t, Reviver<T> f) =>
      f(jsonDecode(jsonEncode(json)));
  static JSON cloneJSON(JSON json) => jsonDecode(jsonEncode(json));
}

/** Optionally map a dictionary key */
T? jmap<T>(JSON m, String k, T Function(JSON) f) {
  if (!m.containsKey(k)) return null;
  var v = m[k];
  if (v == null) return null;
  return f(v);
}

/** Revive elements using f */
List<T> jlist_map<T, P>(List<dynamic> json, T Function(P) f) =>
    json.map((e) => f(e as P)).toList();

/** Convert list to JSON */
List<dynamic> listj(List<IJSON> l) => l.map((e) => e.toJson()).toList();

/** Convert iterable to JSON */
List<dynamic> iterj(Iterable<IJSON> l) => l.map((e) => e.toJson()).toList();
