
import 'package:common/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';

import '../LocalModel.dart';

class ModelView extends StatefulWidget {
	const ModelView({super.key});

	@override
	State<ModelView> createState() => _ModelViewState();
}

class _ModelViewState extends State<ModelView> {

	final TreeViewController ctrl = TreeViewController(
		children: treeFromJson(LocalModel.instance.model.toJson(), "model")
	);

	@override
	Widget build(BuildContext context) =>
		Card(
			child: TreeView(
				onExpansionChanged: (key, state) {
					Node? node = ctrl.getNode(key);
					if (node == null) return;
					// todo: needed?
				},
				controller: ctrl
			)
		);
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
