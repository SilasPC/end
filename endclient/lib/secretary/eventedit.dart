
import 'package:common/EventModel.dart';
import 'package:common/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

// IGNORED: FEAT: edit events
class EventEditPage extends StatefulWidget {
	const EventEditPage({super.key, required this.event});

	final Event event;

	@override
	State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {

	late TreeViewController ctrl;

	@override
	void initState() {
		super.initState();
		ctrl = TreeViewController(children: treeFromJson(widget.event.toJson(), "event"));
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: Colors.transparent,
			appBar: AppBar(
				title: const Text("Edit event"),
				actions: [
					IconButton(
						icon: const Icon(Icons.save),
						onPressed: () {
							Navigator.of(context)
								.pop();
						},
					)
				],
			),
			body: Card(
				child: TreeView(
					controller: ctrl
				)
			),
		);
	}
}

Node treeFromJsonEl(dynamic val, String path, String label) {
	if (val is IJSON) {
		val = val.toJson();
	}
	if (val is JSON) {
		return Node(
			key: path,
			label: label,
			children: treeFromJson(val, path)
		);
	} else if (val is List) {
		return Node(
			key: path,
			label: "$label[${val.length}]",
			children: [
				for (int i = 0; i < val.length; i++)
				treeFromJsonEl(val[i], "$path $i", "$i")
			]
		);
	} else if (val == null) {
		return Node(
			key: path,
			label: "$label: null",
		);
	} else {
		return Node(
			key: path,
			label: "$label: $val"
		);
	}
}

List<Node> treeFromJson(JSON json, String path) {
	return [
		for (var key in json.keys)
		treeFromJsonEl(json[key], "$path $key", key)
	];
}
