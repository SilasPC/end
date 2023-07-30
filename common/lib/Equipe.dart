
import 'dart:convert';
import 'package:common/Event.dart';
import 'package:common/util.dart';
import 'package:http/http.dart' as http;
import 'AbstractEventModel.dart';
import 'model.dart';

Future<List<Event<Model>>> loadModelEvents(int classId) async {
	dynamic schd = await _loadJSON("api/v1/meetings/$classId/schedule");
	if (schd["discipline"] != "endurance")
		throw Exception("Could not load a non-endurance event");

	Model m = Model();
	List<Event<Model>> mevs = [];
	m.rideName = schd["display_name"];
	
	for (var day in schd["days"]) {
		for (var cl in day["meeting_classes"]) {
			String? dist = rgx.firstMatch(cl["name"])?[1];
			String name = rgx2.firstMatch(cl["name"])?[0] ?? cl["name"];
			if (dist == null)
				continue;
			try {
				var id = cl["class_sections"][0]["id"];
				var cat = Category(name, [Loop(int.parse(dist))]);
				List<Event<Model>> evs = [];

				dynamic cls = await _loadJSON("api/v1/class_sections/$id");
				for (var eq in cls["starts"]) {
					var eid = int.parse(eq["start_no"]);
					Equipage e = Equipage(
						int.parse(eq["start_no"]),
						eq["rider_name"],
						eq["horse_name"],
						cat
					);
					cat.equipages.add(e);

					try {
						int loop = 0;
						List<int>? loopDists = [];
						for (var res in eq["results"]) {
							if (res["type"] != "Endurance") break;

							loopDists?.add(double.parse(res["distance"]).floor());
							if (res["start_time"] == null) break;
							var expDep = hmsToUNIX(res["start_time"]);
							evs.add(DepartureEvent("equipe", expDep + 60, eid, loop));

							if (res["arrival"] == null) continue;
							evs.add(ArrivalEvent("equipe", hmsToUNIX(res["arrival"]), eid, loop));

							if (res["pulse_time"] == null) continue;
							var vetTime = hmsToUNIX(res["pulse_time"]);
							evs.add(VetEvent("equipe", vetTime, eid, loop));
							var vetdata = VetData(
								!res.containsKey("reason")
							)..hr1 = res["pulse"];

							if (!vetdata.passed)
								loopDists = null;
							evs.add(ExamEvent("equipe", vetTime + 60, eid, vetdata, loop));
							loop++;
						}

						if (loopDists != null && loopDists.isNotEmpty)
							cat.loops = loopDists.map((d) => Loop(d)).toList();
						if (cat.distance() != int.parse(dist))
							throw Exception("distance loop sum mismatch");
						
					} catch (e) {
						print("$eq exception:");
						print(e);
					}

				}
				List<int> eids = cat.equipages.map((e) => e.eid).toList();
				evs.add(StartClearanceEvent("equipe", hmsToUNIX("00:00:01"), eids));
				evs.addAll(eids.map((eid) => ExamEvent("equipe", hmsToUNIX("00:00:02"), eid, VetData.passed(), null)));

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

	mevs.add(InitEvent("equipe", m));
	mevs.sort((a, b) => b.time - a.time);

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
