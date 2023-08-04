
import 'package:json_annotation/json_annotation.dart';

import '../util.dart';
import 'glob.dart';

part "Model.g.dart";

@JsonSerializable()
class Model extends IJSON {

	String rideName = "";
	Map<String, Category> categories = {};
	@JsonKey(ignore: true)
	Map<int, Equipage> equipages = {};
	List<EventError> errors = [];
	List<EventError> warnings = [];
			
	List<Equipage> vetGate() {
		List<Equipage> eqs = [];
		for (Equipage e in equipages.values) {
			if (e.loops.length == 0)
				continue;
			if (e.loops.last.vet == null && e.loops.last.arrival != null)
				eqs.add(e);
		}
		return eqs;
	}

	List<Equipage> examGate() {
		List<Equipage> eqs = [];
		for (Equipage e in equipages.values) {
			if (e.preExam == null) {
				eqs.add(e);
				continue;
			}
			if (e.loops.length == 0)
				continue;
			if (e.loops.last.vet != null && e.loops.last.data == null)
				eqs.add(e);
		}
		return eqs;
	}

	Model();
	JSON toJson() => _$ModelToJson(this);
	factory Model.fromJson(JSON json) {
		Model m = _$ModelFromJson(json);
		for (var cat in m.categories.values) {
			for (var eq in cat.equipages) {
				m.equipages[eq.eid] = eq;
				eq.category = cat;
				for (int i = 0; i < eq.loops.length; i++) {
					eq.loops[i].loop = cat.loops[i];
				}
			}
		}
		return m;
	}

	String toResultCSV() {
		List<String> lines = [];
		hms(int? unix) => unix == null ? "-" : unixHMS(unix);

		for (var cat in categories.values) {
			lines.add([
				"${cat.name} ${cat.distance()}km",
				"StartNumber",
				"Rider",
				"Horse",
				for (var lp in cat.loops) ... [
					"Loop ${cat.loops.indexOf(lp) + 1} ${lp.distance}km",
					"Departure",
					"Arrival",
					"Vet",
				],
			].join(","));
			for (var eq in cat.equipages) {
				lines.add([
					"",
					eq.eid,
					eq.rider.replaceAll(",", ""),
					eq.horse.replaceAll(",", ""),
					for (var ld in eq.loops) ... [
						"",
						hms(ld.expDeparture),
						hms(ld.arrival),
						hms(ld.vet),
					],
				].join(","));
			}
		}
		return lines.join("\n");
	}

}