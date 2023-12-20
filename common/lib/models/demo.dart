import 'package:common/models/glob.dart';
import 'package:common/util.dart';

import '../EnduranceEvent.dart';
import '../EventModel.dart';

List<Event<EnduranceModel>> demoInitEvent(String author, int startTime) =>
    [InitEvent(startTime - FIVE_MINS, author, demoModel(author, startTime))];

EnduranceModel demoModel(String author, int now) {
  var c1 = Category(null, "Kort clearround", [Loop(1, 3)], now + FIVE_MINS)
    ..clearRound = true;
  var c2 = Category(null, "Kort ideal", [Loop(1, 3)], now + FIVE_MINS)
    ..idealSpeed = 10
    ..minSpeed = 8
    ..maxSpeed = 12;
  var c3 =
      Category(null, "Lang fri", [Loop(1, 3), Loop(1, 3)], now + FIVE_MINS);

  var eqs = [
    Equipage(1, "Anna Andersen", "Aladdin", c1),
    Equipage(2, "Bent Hansen", "Børge", c1),
    Equipage(10, "Camilla Clausen", "Candy", c2),
    Equipage(11, "Didde Dybkjær", "Diego", c2),
    Equipage(21, "Emma Eriksen", "Etopia", c3),
    Equipage(22, "Freja Frost", "Fargo", c3),
  ];

  var m = EnduranceModel()
    ..rideName = "Demo ridt"
    ..addCategories([c1, c2, c3])
    ..addEquipages(eqs);
  return m;
}
