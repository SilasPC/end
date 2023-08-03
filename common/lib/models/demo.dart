
String demoInitEvent(int startTime) => """
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
							"distance": 1
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
							"distance": 1
						},
						{
							"distance": 1
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
