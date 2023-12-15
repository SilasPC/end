
import 'package:common/Equipe.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/MetaModel.dart';
import 'package:common/util.dart';
import 'package:test/test.dart';

void main() {
	test("equipe loading", () async {
		var meets = await EquipeMeeting.loadMany();
      var futs = futStream(
         meets.map((m) async {
            var evs = await m.loadEvents("");
            return (m,evs);
         })
      )
      .handleError((e,st) {
         print(e);
         print(st);
      });
		await for (var (m,evs) in futs) {
			print(m);
         var model = EventModel(MetaModel());
			model.add(evs);
         expect(model.model.categories.isNotEmpty, true);
			expect(model.model.errors, []);
		}
	}, skip: true);
}
