
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'package:common/EnduranceEvent.dart';
import 'package:common/event_model/Event.dart';
import 'package:common/models/Model.dart';
import 'package:common/util.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:esys_client/v2/dashboard/component/event_tile.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:provider/provider.dart';

class DataView extends StatelessWidget {
	const DataView({super.key});

	@override
	Widget build(BuildContext context) {
		var model = context.read<LocalModel>();
		var ctrl = TreeViewController(children: treeFromJson(model.model.toJson(), "model"));
		return Row(
			children: [
				Card(
					child: SizedBox(
						width: 350,
						child: Column(
							children: [
								...cardHeader("Events"),
								Expanded(
									child: ListView.builder(
										itemCount: model.events.length,
										itemBuilder: (context, i) {
											var evIdx = model.events.length - 1 - i;
											var event = model.events[evIdx];
											bool isDeleted = model.deletes.contains(event);
											return EventTile(
												model: model,
												event: event,
												isDeleted: isDeleted
											);
										}
									),
								)
							],
						),
					)
				),
				Card(
					child: SizedBox(
						width: 350,
						child: Column(
							children: [
								Container(
									alignment: Alignment.center,
									padding: const EdgeInsets.all(8),
									child: Text(
										"Model tree",
										style: TextStyle(
											fontSize: 20
										)
									),
								),
								Divider(),
								Expanded(
									child: TreeView(
										controller: ctrl
									),
								)
							]
						)
					)
				)
			],
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
