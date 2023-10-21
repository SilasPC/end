
import 'package:common/EnduranceEvent.dart';
import 'package:common/Equipe.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/MetaModel.dart';
import 'package:common/util.dart';
import 'package:test/test.dart';

void main() {
	test("equipe loading", () async {
		var meets = await EquipeMeeting.loadMany();
		await for (var evs in futStream(meets.map((m) => m.loadEvents())).handleError(print)) {
			var model = EventModel(MetaModel());
			model.add(evs);
			expect(model.model.errors.isEmpty, true);
			expect(model.model.warnings.isEmpty, true);
		}
	}, skip: true);
}
