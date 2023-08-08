
import 'dart:convert';

import 'package:common/EnduranceEvent.dart';
import 'package:common/util.dart';

List<EnduranceEvent> demoInitEvent(int startTime) =>
	jlist_map(jsonDecode(_demoInitEvent(startTime)) as List, eventFromJSON);

String _demoInitEvent(int startTime) => """
[
	{
		"kind": "init",
		"author": "root",
		"model": {
			"rideName": "Demo",
			"errors": [],
			"warnings": [],
			"categories": {
				"1km": {
					"name": "1km",
					"loops": [
						{
							"distance": 1,
							"restTime": 3
						}
					],
					"startTime": $startTime,
					"equipages": [
						{
							"status": "WAITING",
							"eid": 1,
							"rider": "Alex",
							"horse": "Bob",
							"dsqReason": null,
							"preExam": null,
							"loops": [],
							"currentLoop": null
						},
						{
							"status": "WAITING",
							"eid": 2,
							"rider": "Casey",
							"horse": "Doozie",
							"dsqReason": null,
							"preExam": null,
							"loops": [],
							"currentLoop": null
						}
					]
				},
				"2km": {
					"name": "2km",
					"loops": [
						{
							"distance": 1,
							"restTime": 3
						},
						{
							"distance": 1,
							"restTime": 3
						}
					],
					"startTime": ${startTime+120},
					"equipages": [
						{
							"status": "WAITING",
							"eid": 3,
							"rider": "Elvis",
							"horse": "Fred",
							"dsqReason": null,
							"preExam": null,
							"loops": [],
							"currentLoop": null
						},
						{
							"status": "WAITING",
							"eid": 4,
							"rider": "Ginny",
							"horse": "Hans",
							"dsqReason": null,
							"preExam": null,
							"loops": [],
							"currentLoop": null
						}
					]
				}
			}
		}
	}
]
""";
