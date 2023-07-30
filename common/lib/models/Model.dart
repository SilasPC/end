
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

}
