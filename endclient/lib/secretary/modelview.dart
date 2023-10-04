
import 'package:common/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:provider/provider.dart';

import '../local_model/LocalModel.dart';

class ModelView extends StatefulWidget {
	const ModelView({super.key});

	@override
	State<ModelView> createState() => _ModelViewState();
}

class _ModelViewState extends State<ModelView> {

	@override
	Widget build(BuildContext context) {
		var model = context.watch<LocalModel>();
		var ctrl = TreeViewController(children: treeFromJson(model.model.toJson(), "model"));
		return Card(
			child: TreeView(
				controller: ctrl
			)
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
