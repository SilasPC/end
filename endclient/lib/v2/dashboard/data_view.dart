
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';

import 'package:common/EnduranceEvent.dart';
import 'package:common/event_model/Event.dart';
import 'package:common/models/Model.dart';
import 'package:common/util.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/util/input_modals.dart';
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

class EventTile extends StatelessWidget {

  const EventTile({
    super.key,
    required this.model,
    required this.event,
    required this.isDeleted,
  });

  final LocalModel model;
  final Event<Model> event;
  final bool isDeleted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
    	onLongPress: () {
    	showChoicesModal(
    		context,
    		[/* "Edit", */ "Delete", "Move"],
    		(s) {
    			switch (s) {
    				/* case "Edit":
    					Navigator.of(context)
    						.push(MaterialPageRoute(
    							builder: (context) => EventEditPage(event: event),
    						));
    					break; */
    				case "Delete":
    					context.read<LocalModel>().addSync([], [event]);
    					break;
    				case "Move":
    					showHMSPicker(
    						context,
    						fromUNIX(event.time),
    						(dt) {
    							// TODO: this is a hack
    							var json = jsonDecode(event.toJsonString());
    							json["time"] = toUNIX(dt);
    							var updated = eventFromJSON(json);
    							context.read<LocalModel>().addSync([updated], [event]);
    						}
    					);
    					break;
    				default:
    					break;
    			}
    		}
    	);
    },
    	leading: Column(
    		mainAxisAlignment: MainAxisAlignment.center,
    		children: [
    			Text(unixHMS(event.time)),
    			Text(event.author, style: const TextStyle(color: Colors.grey)),
    		]
    	),
    	title: Text(
    		event.runtimeType.toString(),
    		style: isDeleted ? const TextStyle(
    			decoration: TextDecoration.lineThrough,
    			decorationColor: Colors.black,
    			decorationThickness: 5,
    		) : null
    	),
    	subtitle: Text(event.toString(), overflow: TextOverflow.fade),
    	/* trailing: err != null
    		? Text(err.description)
    		: null */
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
