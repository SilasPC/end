import 'package:common/models/glob.dart';
import 'package:test/test.dart';

void main() {
  group("endurance model", () {
    const HOUR = 3600;
    // const FIVE_MINS = 5 * 60;

    test("time limits", () {
      const START_TIME = 0;

      var c = Category(null, "Ideal", [Loop(12, 0)], START_TIME)
        ..clearRound = true
        ..minSpeed = 2
        ..idealSpeed = 4
        ..maxSpeed = 6;
      var e = Equipage(100, "Rider", "Horse", c)..startOffsetSecs = 1 * HOUR;

      expect(c.minRideTime(), 2 * HOUR);
      expect(c.idealRideTime(), 3 * HOUR);
      expect(c.maxRideTime(), 6 * HOUR);

      expect(e.minFinishTime(), 3 * HOUR);
      expect(e.idealFinishTime(), 4 * HOUR);
      expect(e.maxFinishTime(), 7 * HOUR);
    });

    test("loop timing", () {
      var ld = LoopData(Loop(10, 10))
        ..expDeparture = 0 * HOUR
        ..arrival = 1 * HOUR
        ..vet = 2 * HOUR;

      expect(ld.timeToArrival, 1 * HOUR);
      expect(ld.timeToVet, 2 * HOUR);

      expect(ld.recoveryTime, 1 * HOUR);

      expect(ld.speed(), 5);
      expect(ld.speed(finish: true), 10);
    });

    // TEST: ranking
    /* test("ranking", () {

			var c = Category(null, "One loop", [
				Loop(10, 40),
			], 0);
			
			int nextEid = 100;
			Equipage eq(
				int rideTime1,
				int coolTime1,
				[bool passed = true]
			) => Equipage(++nextEid, nextEid.toString(), nextEid.toString(), c)
				..loops = [
					LoopData(c.loops.first)
						..expDeparture = 0
						..departure = 0
						..arrival = rideTime1
						..vet = rideTime1 + coolTime1
						..data = VetData(passed)
				];

		}); */
  });
}
