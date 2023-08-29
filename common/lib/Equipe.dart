
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

	EquipeMeeting(this.name, this.id);
}

Future<List<EquipeMeeting>> loadRecentMeetings() async {
	dynamic res = await _loadJSON("api/v1/meetings/recent");
	List<dynamic> recent = res as List;
	recent.retainWhere((e) => e["discipline"] == "endurance");
	return recent
		.map((e) => EquipeMeeting(e["display_name"], e["id"]))
		.toList();
}

Future<List<Event<Model>>> loadModelEvents(int classId) async {
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
			String? distStr = rgx.firstMatch(cl["name"])?[1];
			if (distStr == null) continue;
			int dist = int.parse(distStr);
			String name = rgx2.firstMatch(cl["name"])?[0] ?? cl["name"];

			if (m.categories.containsKey(name)) {
				int i = 1;
				while (m.categories.containsKey("$name $i")) {
					i++;
				}
				name = "$name $i";
			}
			try {
				var id = cl["class_sections"][0]["id"];
				var catStartTime = UNIX_FUTURE;
				var cat = Category(name, [], catStartTime);
				List<Event<Model>> evs = [];

				dynamic cls = await _loadJSON("api/v1/class_sections/$id");
				for (var eq in cls["starts"]) {
					var eid = int.parse(eq["start_no"]);
					Equipage e = Equipage(
						eid,
						eq["rider_name"],
						eq["horse_name"],
						cat
					);
					cat.equipages.add(e);

					try {
						int loop = 0;
						List<int>? loopDists = [];
						List results = eq["results"] as List;
						bool dsqPreExam = true;
						bool retirePreExam = results[0]["reason"] == "RET";
						if (!retirePreExam) {
							for (int i = 0; i < results.length; i++) {
								var res = results[i];
								if (res["type"] != "Endurance") break;
								bool passed = results[i]["reason"] == null;
								bool retire = results[i+1]["reason"] == "RET";

								loopDists?.add(double.parse(res["distance"]).floor());
								if (res["start_time"] == null) break;
								var expDep = hmsToUNIX(res["start_time"]);
								catStartTime = min(catStartTime, expDep);

								if (res["arrival"] == null) break;
								dsqPreExam = false;
								evs.add(DepartureEvent("equipe", expDep + 60, eid, loop));
								evs.add(ArrivalEvent("equipe", hmsToUNIX(res["arrival"]), eid, loop));

								if (res["pulse_time"] == null) break;
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
								cat.loops = loopDists.map((d) => Loop(d, 40)).toList(); // TODO: assummed 40 min breaks
						}
						
					} catch (e) {
						print("$eq exception:");
						print(e);
					}

				}

				if (cat.distance() == 0) {
					throw Exception("distance not found");
				}
				if (cat.distance() != dist) {
					print("$name distance mismatch (needed $dist, found ${cat.distance()})");
				}

				List<int> eids = cat.equipages.map((e) => e.eid).toList();
				evs.add(StartClearanceEvent("equipe", hmsToUNIX("00:00:01"), eids));

				cat.startTime = catStartTime;

				// okay, write into model
				m.categories[cat.name] = cat;
				mevs.addAll(evs);
				for (var eq in cat.equipages)
					m.equipages[eq.eid] = eq;
				
			} catch (e) {
				print(e);
			}
		}
	}

	mevs.sort();

	return mevs;

}

RegExp rgx = RegExp(r"(\d+) ?km");
RegExp rgx2 = RegExp(r"[LMS][ABCDE]|CEI.*\d?\*+");

Future<dynamic> _loadJSON(String loc) async {
	var res = await http.get(Uri.https("online.equipe.com", loc));
	if (res.statusCode != 200)
		throw Exception("Equipe $loc status ${res.statusCode}");
	return jsonDecode(res.body);
}
