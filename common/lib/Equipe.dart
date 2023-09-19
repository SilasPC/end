
import 'dart:convert';
import 'dart:math';
import 'package:common/EnduranceEvent.dart';
import 'package:common/util.dart';
import 'package:http/http.dart' as http;
import 'EventModel.dart';
import 'models/glob.dart';

class EquipeMeeting {
	final String name;
	final int id;

	static Future<List<EquipeMeeting>> loadRecent() => _loadRecentMeetings();

	EquipeMeeting(this.name, this.id);

	Future<List<Event<Model>>> loadEvents() => _loadModelEvents(id);
}

Future<List<EquipeMeeting>> _loadRecentMeetings() async {
	dynamic res = await _loadJSON("api/v1/meetings/recent");
	List<dynamic> recent = res as List;
	recent.retainWhere((e) => e["discipline"] == "endurance");
	return recent
		.map((e) => EquipeMeeting(e["display_name"], e["id"]))
		.toList();
}

/// TODO: determine actual rest time?
const TYPICAL_REST_TIME = 40;

Future<List<Event<Model>>> _loadModelEvents(int classId) async {
	dynamic schd = await _loadJSON("api/v1/meetings/$classId/schedule");
	if (schd["discipline"] != "endurance")
		throw Exception("Could not load a non-endurance event");

	Model m = Model();
	List<Event<Model>> mevs = [InitEvent("equipe", m)];
	m.rideName = schd["display_name"];

	var days = [schd];
	if ((schd as JSON).containsKey("days")) {
		days = schd["days"];
	}
	
	for (var day in days) {
		for (var cl in day["meeting_classes"]) {

			var tup = _parseCategory(cl, m);
			if (tup == null) continue;
			var cat = tup.a;
			var dist = tup.b;

			try {

				var cls = await _loadJSON("api/v1/class_sections/${cat.equipeId!}");
				_parseEquipages(cls["starts"], cat, mevs);

				if (cat.distance() != dist) {
					_guessCategoryLoops(cat, dist);
				}

				for (var eq in cat.equipages) {
					m.equipages[eq.eid] = eq;
				}
				
			} catch (e) {
				print(e);
			}
		}
	}

	mevs.sort();

	return mevs;

}

Tuple<Category, int>? _parseCategory(dynamic meeting_class, Model model) {
	String name = meeting_class["name"];
	var class_sections = meeting_class["class_sections"] as List;
	if (class_sections.isEmpty) return null;
	var equipeId = class_sections.first["id"];
	String? distStr = rgxDist.firstMatch(name)?[1];
	if (distStr == null) return null;
	int dist = int.parse(distStr);
	String lvl = rgxCatLvl.firstMatch(name)?[0] ?? name;

	int? minSpeed = maybe(rgxMinSpd.firstMatch(name)?[1], int.parse);
	int? maxSpeed = maybe(rgxMaxSpd.firstMatch(name)?[1], int.parse);

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

	var cat = model.categories[lvl] =
		Category(equipeId, lvl, [], UNIX_FUTURE)
			..minSpeed = minSpeed
			..maxSpeed = maxSpeed;

	return Tuple(cat, dist);
}

void _guessCategoryLoops(Category cat, int dist) {
	print("Guessing loops for ${cat.name}");

	int lenGuess = (dist / 30).ceil();

	int ldist = (dist / lenGuess).ceil();
	int fdist = dist - (ldist * (lenGuess - 1));

	for (int i = 0; i < lenGuess - 1; i++) {
		cat.loops.add(Loop(ldist, TYPICAL_REST_TIME));
	}
	cat.loops.add(Loop(fdist, TYPICAL_REST_TIME));
}

void _parseEquipages(dynamic equipages, Category cat, List<Event> evs) {
	bool hasResults = false;
	for (var eq in equipages) {
		var eid = int.parse(eq["start_no"]);
		Equipage e = Equipage(
				eid,
				eq["rider_name"],
				eq["horse_name"],
				cat
			);
			cat.equipages.add(e);

			List results = eq["results"] as List;
			if (results.isNotEmpty) {
				hasResults = true;
				try {
					int loop = 0;
					List<int>? loopDists = [];
					bool dsqPreExam = true;
					bool retirePreExam = results[0]["reason"] == "RET";
					if (!retirePreExam) {
						for (int i = 0; i < results.length; i++) {
							var res = results[i];
							if (res["type"] != "Endurance") break;
							bool passed = nullOrEmpty(res["reason"]);
							bool retire = results[i+1]["reason"] == "RET";

							loopDists?.add(double.parse(res["distance"]).floor());
							if (nullOrEmpty(res["start_time"])) break;
							var expDep = hmsToUNIX(res["start_time"]);
							cat.startTime = min(cat.startTime, expDep);

							if (nullOrEmpty(res["arrival"])) break;
							dsqPreExam = false;
							evs.add(DepartureEvent("equipe", expDep + 60, eid, loop));
							evs.add(ArrivalEvent("equipe", hmsToUNIX(res["arrival"]), eid, loop));

							if (nullOrEmpty(res["pulse_time"])) break;
							var vetTime = hmsToUNIX(res["pulse_time"]);
							evs.add(VetEvent("equipe", vetTime, eid, loop));
							var vetdata = VetData(
								passed
							)..hr1 = res["pulse"];

							evs.add(ExamEvent("equipe", vetTime + 60, eid, vetdata, loop));
							if (retire)
								evs.add(RetireEvent("equipe", vetTime + 61, eid));
							loop++;
							if (!vetdata.passed || retire) {
								loopDists = null;
								break;
							}
						}
					}
					
					evs.add(ExamEvent("equipe", hmsToUNIX("00:00:02"), eid, VetData(!dsqPreExam), null));
					if (retirePreExam)
						evs.add(RetireEvent("equipe", hmsToUNIX("00:00:03"), eid));

					if (loopDists != null && loopDists.isNotEmpty) {
						int sum = loopDists.reduce((a,b) => a+b);
						if (sum > cat.distance())
							cat.loops = loopDists.map((d) => Loop(d, TYPICAL_REST_TIME)).toList();
					}
					
				} catch (e, st) {
					print("$eq exception:");
					print(e);
					print(st);
				}
			}

		}
		List<int> eids = cat.equipages.map((e) => e.eid).toList();
		if (hasResults) {
			evs.add(StartClearanceEvent("equipe", hmsToUNIX("00:00:01"), eids));
		}
}

RegExp rgxDist = RegExp(r"(\d+)(?:[.,]\d+)?\s?km");
RegExp rgxCatLvl = RegExp(r"[LMS][ABCDE]|CEI.*\d?\*+");
RegExp rgxMinSpd = RegExp(r"min\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);
RegExp rgxMaxSpd = RegExp(r"max\D*(\d+)(?:[.,]\d+)?\s?km", caseSensitive: false);

Future<dynamic> _loadJSON(String loc) async {
	var res = await http.get(Uri.https("online.equipe.com", loc));
	if (res.statusCode != 200)
		throw Exception("Equipe $loc status ${res.statusCode}");
	return jsonDecode(res.body);
}

bool nullOrEmpty(str) => str == null || str == "";
