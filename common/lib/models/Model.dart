
import 'package:json_annotation/json_annotation.dart';

import 'dart:convert';
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

	void addCategories(Iterable<Category> cats) {
		for (var cat in cats) {
			if (categories.containsKey(cat.name)) {
				throw StateError("Duplicate category name ${cat.name}");
			}
			categories[cat.name] = cat;
		}
	}

	void addEquipages(Iterable<Equipage> eqs) {
		for (var e in eqs) {
			if (!categories.containsValue(e.category)) {
				throw StateError("Category ${e.category} not in model");
			}
			if (equipages.containsKey(e.eid)) {
				throw StateError("Duplicate eid ${e.eid}");
			}
			if (!e.category.equipages.contains(e)) {
				e.category.equipages.add(e);
			}
			equipages[e.eid] = e;
		}
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

	Model clone() => Model.fromJson(jsonDecode(jsonEncode(toJson())));

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
						hms(ld.departure != null ? ld.expDeparture : null),
						hms(ld.arrival),
						hms(ld.vet),
					],
				].join(","));
			}
		}
		return lines.join("\n");
	}

}
