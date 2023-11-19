
import 'package:common/models/glob.dart';
import 'package:common/util.dart';

import '../EnduranceEvent.dart';
import '../EventModel.dart';

const FIVE_MINS = 5 * 60;

List<Event<Model>> demoInitEvent(int startTime) =>
	[InitEvent(startTime - FIVE_MINS, "demo", demoModel())];

Model demoModel() {	

	var now = nowUNIX();

	var c1 = Category(null, "Kort clearround", [Loop(1, 3)], now + FIVE_MINS)
		..clearRound = true;
	var c2 = Category(null, "Kort ideal", [Loop(1, 3)], now + FIVE_MINS)
		..idealSpeed = 10
		..minSpeed = 8
		..maxSpeed = 12;
	var c3 = Category(null, "Lang fri", [Loop(1, 3), Loop(1, 3)], now + FIVE_MINS);

	var eqs = [
		Equipage(1, "Anna", "Amouroq", c1),
		Equipage(2, "Bjarke", "Børge", c1),

		Equipage(10, "Cathrine", "Comeback", c2),
		Equipage(11, "Didde", "Donnager", c2),

		Equipage(21, "Erik", "Enhjørningen", c3),
		Equipage(22, "Freja", "Felix", c3),
	];

	var m = Model()
		..rideName = "Demo ridt"
		..addCategories([c1,c2,c3])
		..addEquipages(eqs);
	return m;
	
}
