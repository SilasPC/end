import 'dart:convert';
import 'dart:math';
import 'package:common/EnduranceEvent.dart';
import 'package:common/util.dart';
import 'package:http/http.dart' as http;
import '../EventModel.dart';
import '../models/glob.dart';

class EquipeMeeting {
  final String name;
  final int id;

  static Future<List<EquipeMeeting>> loadRecent() =>
      _loadMeetings("api/v1/meetings/recent");
  static Future<List<EquipeMeeting>> loadMany() =>
      _loadMeetings("api/v1/meetings");

  EquipeMeeting(this.name, this.id);

  Future<List<Event<EnduranceModel>>> loadEvents(String author) =>
      loadModelEvents(id, author);

  @override
  String toString() => "Meeting($name)";

  // FEAT: upload to equipe
}

Future<List<EquipeMeeting>> _loadMeetings(String uri) async {
  dynamic res = await _loadJSON(uri);
  List<dynamic> recent = res as List;
  recent.retainWhere((e) => e["discipline"] == "endurance");
  return recent.map((e) => EquipeMeeting(e["display_name"], e["id"])).toList();
}

/// IGNORED: TODO: determine actual rest time?
const TYPICAL_REST_TIME = 40;

Future<List<Event<EnduranceModel>>> loadModelEvents(
    int classId, String author) async {
  dynamic schd = await _loadJSON("api/v1/meetings/$classId/schedule");
  if (schd["discipline"] != "endurance")
    throw Exception("Could not load a non-endurance event");

  EnduranceModel m = EnduranceModel()..equipeId = classId;
  List<Event<EnduranceModel>> mevs = [InitEvent(author, 0, m)];
  m.rideName = schd["display_name"];

  var days = [schd];
  if ((schd as JSON).containsKey("days")) {
    days = schd["days"];
  }

  var classes = days
      .expand((day) => day["meeting_classes"] ?? [])
      .map((cl) => _parseCategory(cl, m));

  await for (var tup in futStream(classes)) {
    if (tup == null) continue;
    var (cat, dist, cls) = tup;

    try {
      var evs = <EnduranceEvent>[];
      var startTimes = _parseEquipages(cls["starts"], cat, evs, author);
      mevs.addAll(evs);

      var catDist = cat.distance();
      if (catDist == 0) {
        _guessCategoryLoops(cat, dist ?? 30 /* TODO: what to put here? */);
      } else if (catDist != dist && dist != null) {
        print("distance mismatch ${cat.name}: $catDist != $dist");
      }

      if (startTimes.isNotEmpty) {
        cat.startTime = startTimes.values.reduce(min);
        for (var eq in startTimes.entries) {
          eq.key.startOffsetSecs = eq.value - cat.startTime;
        }
      }

      for (var eq in cat.equipages) {
        m.equipages[eq.eid] = eq;
      }
    } catch (e, st) {
      print(e);
      print(st);
    }
  }

  mevs.sort();

  return mevs;
}

Future<(Category, int?, dynamic)?> _parseCategory(
    dynamic meeting_class, EnduranceModel model) async {
  if (meeting_class["name"] == null) {
    return null;
  }
  String name = meeting_class["name"];
  var class_sections = (meeting_class["class_sections"] ?? []) as List;
  if (class_sections.isEmpty) return null;
  int equipeId = class_sections.first["id"];

  var cls = await _loadJSON("api/v1/class_sections/${equipeId}");
  if (nullOrEmpty((cls["starts"] as List).firstOrNull?["start_no"])) {
    print("skip cat $name");
    return null;
  }

  int? dist = maybe(rgxDist.firstMatch(name)?[1], int.parse);
  String lvl = rgxCatLvl.firstMatch(name)?[0] ?? name;

  int? minSpeed = maybe(rgxMinSpd.firstMatch(name)?[1], int.parse);
  int? maxSpeed = maybe(rgxMaxSpd.firstMatch(name)?[1], int.parse);
  int? idealSpeed = maybe(rgxIdeal.firstMatch(name)?[1], int.parse);
  bool clearRound = rgxClearRound.hasMatch(name);

  var other = model.categories[lvl];
  if (other != null) {
    other.name += " 1";
  }
  if (model.categories.containsKey("$lvl 1")) {
    int i = 2;
    while (model.categories.containsKey("$lvl $i")) {
      i++;
    }
    lvl += " $i";
  }

  var cat = model.categories[lvl] = Category(equipeId, lvl, [], UNIX_FUTURE)
    ..clearRound = clearRound
    ..idealSpeed = idealSpeed
    ..minSpeed = minSpeed
    ..maxSpeed = maxSpeed;

  return (cat, dist, cls);
}

void _guessCategoryLoops(Category cat, int dist) {
  print("Guessing loops for ${cat.name} ${cat.distance()}km");

  int lenGuess = (dist / 30).ceil();

  int ldist = (dist / lenGuess).ceil();
  int fdist = dist - (ldist * (lenGuess - 1));

  for (int i = 0; i < lenGuess - 1; i++) {
    cat.loops.add(Loop(ldist, TYPICAL_REST_TIME));
  }
  cat.loops.add(Loop(fdist, TYPICAL_REST_TIME));
}

Map<Equipage, int> _parseEquipages(
    dynamic equipages, Category cat, List<Event> evs, String author) {
  bool hasResults = false;
  Map<Equipage, int> startTimes = {};
  for (var eq in equipages) {
    if (nullOrEmpty(eq["start_no"])) {
      // should be ignored by _parseCategory in such a case
      print("no eid for ${eq["rider_name"]} ${cat.name}");
      continue;
    }
    var eid = int.parse(eq["start_no"]);
    Equipage e = Equipage(eid, eq["rider_name"], eq["horse_name"], cat);
    cat.equipages.add(e);

    List results = (eq["results"] ?? []);
    if (results.isNotEmpty) {
      int _prevTime = 0;
      int nextTime(int unix) =>
          _prevTime = (unix <= _prevTime ? _prevTime + 1 : unix);

      hasResults = true;
      try {
        List<int>? loopDists = [];
        bool dsqPreExam = true;
        bool retirePreExam = results[0]["reason"] == "RET";
        if (!retirePreExam) {
          for (int i = 0; i < results.length; i++) {
            final loop = i;
            var res = results[i];
            if (res["type"] != "Endurance") break;
            bool passed = nullOrEmpty(res["reason"]);
            bool retire = results[i + 1]["reason"] == "RET";

            loopDists?.add(res["distance"].floor());
            if (nullOrEmpty(res["start_time"])) break;
            var expDep = hmsToUNIX(res["start_time"]);
            cat.startTime = min(cat.startTime, expDep);
            if (i == 0) {
              startTimes[e] = expDep;
            }

            if (nullOrEmpty(res["arrival"])) break;
            dsqPreExam = false;
            evs.add(DepartureEvent(author, expDep + 60, eid, loop));
            evs.add(ArrivalEvent(
                author, nextTime(hmsToUNIX(res["arrival"])), eid, loop));

            if (nullOrEmpty(res["pulse_time"])) break;
            // IGNORED: FIXME: in ranum23, 404, MA, loop 1, this is null,
            //      : despite FTQ-GA for loop 1, thus the ftq is not registered
            var vetTime = hmsToUNIX(res["pulse_time"]);
            evs.add(VetEvent(author, nextTime(vetTime), eid, loop));
            var vetdata = VetData(passed)..hr1 = res["pulse"];

            evs.add(ExamEvent(author, nextTime(vetTime), eid, vetdata, loop));
            if (retire)
              evs.add(RetireEvent(author, nextTime(vetTime + 61), eid));
            if (!vetdata.passed || retire) {
              loopDists = null;
              break;
            }
          }
        }

        evs.add(ExamEvent(
            author, hmsToUNIX("00:00:02"), eid, VetData(!dsqPreExam), null));
        if (retirePreExam)
          evs.add(RetireEvent(author, hmsToUNIX("00:00:03"), eid));

        if (loopDists != null && loopDists.length > cat.loops.length) {
          cat.loops = loopDists.map((d) => Loop(d, TYPICAL_REST_TIME)).toList();
        }
      } catch (e, st) {
        print(e);
        print(st);
      }
    }
  }
  List<int> eids = cat.equipages.map((e) => e.eid).toList();
  if (hasResults) {
    evs.add(StartClearanceEvent(author, hmsToUNIX("00:00:01"), eids));
  }
  return startTimes;
}

RegExp rgxDist = RegExp(r"(\d+)(?:[.,]\d+)?\s?km");
RegExp rgxCatLvl = RegExp(r"[LMS][ABCDE]|CEI.*\d?\*+");
RegExp rgxMinSpd =
    RegExp(r"min\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxMaxSpd =
    RegExp(r"max\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxIdeal =
    RegExp(r"idealtid\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxClearRound = RegExp(r"clear.*round", caseSensitive: false);

Future<dynamic> _loadJSON(String loc) async {
  var res = await http.get(Uri.https("online.equipe.com", loc));
  if (res.statusCode != 200)
    throw Exception("Equipe $loc status ${res.statusCode}");
  return jsonDecode(res.body);
}

bool nullOrEmpty(str) => str == null || str == "";
