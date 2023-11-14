
import 'dart:convert';

import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/secretary/eventedit.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../local_model/LocalModel.dart';

class EventView extends StatefulWidget {
	const EventView({super.key});
	@override
	State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {

	String filterType = "all";
	bool Function(Event<Model>)? filterFn;

	Widget header(LocalModel model) =>
		Card(
			child: DropdownButton<String>(
				value: filterType,
				items: [
					const DropdownMenuItem(
						value: "all",
						child: Text("All"),
					),
					const DropdownMenuItem(
						value: "admin",
						child: Text("Administration"),
					),
					for (var eq in model.model.equipages.values)
					DropdownMenuItem(
						value: "${eq.eid}",
						child: Text("${eq.eid} ${eq.rider}", overflow: TextOverflow.fade,),
					),
				],
				onChanged: (value) =>
					setState(() {
						filterType = value ?? "all";
						switch (value) {
							case null:
							case "all":
								filterFn = null;
								break;
							case "admin":
								filterFn = adminOnly;
								break;
							default:
								int eid = int.parse(value!);
								filterFn = (e) => (e as EnduranceEvent).affectsEquipage(eid);
						}
					}),
			),
		);

	@override
	Widget build(BuildContext context) {

		var model = context.watch<LocalModel>();

		Map<Event, EventError> errs = {};
		for (var err in model.model.errors) {
			errs[model.events.byInsertionIndex(err.causedBy)] = err;
		}

		var evs = filterFn != null ? model.events.iterator.where(filterFn!).toList() : model.events.iterator.toList();

		return Container(
			padding: const EdgeInsets.all(10),
			child: Column(
				children: [
					header(model),
					Expanded(
						child: Card(
							child: ListView.separated(
								itemCount: evs.length,
								separatorBuilder: (context, _) => const Divider(),
								itemBuilder: (context, i) {
									var evIdx = evs.length - 1 - i;
									var e = evs[evIdx];
									var err = errs[e];
									bool deleted = model.deletes.contains(e);
									return ListTile(
										onLongPress: () {
											showChoicesModal(
												context,
												["Edit", "Delete", "Move"],
												(s) {
													switch (s) {
														case "Edit":
															Navigator.of(context)
																.push(MaterialPageRoute(
																	builder: (context) => EventEditPage(event: e),
																));
															break;
														case "Delete":
															model.addSync([], [e]);
															break;
														case "Move":
															showHMSPicker(
																context,
																fromUNIX(e.time),
																(dt) {
																	// TODO: this is a hack
																	var json = jsonDecode(e.toJsonString());
																	json["time"] = toUNIX(dt);
																	var e2 = eventFromJSON(json);
																	model.addSync([e2], [e]);
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
												Text(unixHMS(e.time)),
												Text(e.author, style: const TextStyle(color: Colors.grey)),
											]
										),
										title: Text(e.runtimeType.toString()),
										subtitle: Text(e.toString(), overflow: TextOverflow.fade),
										trailing: err != null
											? Text(err.description)
											: (
												deleted
													? const Icon(Icons.delete)
													: null
											)
									);
								},
							),
						),
					)
				],
			)
		);
	}
}

bool adminOnly(Event e) =>
	e is InitEvent ||
	e is ChangeCategoryEvent;
