
import 'package:common/AbstractEventModel.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../LocalModel.dart';

class EventView extends StatefulWidget {
	const EventView({super.key});
	@override
	State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {

	String filterType = "all";
	bool Function(EnduranceEvent)? filterFn;

	Widget header() =>
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
					for (var eid in LocalModel.instance.model.equipages.values)
					DropdownMenuItem(
						value: "$eid",
						child: Text("$eid"),
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
								filterFn = (e) => e.affectsEquipage(eid);
						}
					}),
			),
		);
	
	@override
	Widget build(BuildContext context) =>
		Consumer<LocalModel>(
			builder: (context, value, child) {

				Map<EventId, EventError> errs = {};
				for (var err in value.model.errors) {
					errs[err.causedBy] = err;
				}

				return Container(
					padding: const EdgeInsets.all(10),
					child: Column(
						children: [
							// header(), // todo: filtering requires iterated builder
							Expanded(
								child: Card(
									child: ListView.builder(
										itemCount: value.events.length * 2,
										itemBuilder: (context, i) {
											if (i % 2 == 1) return const Divider();
											List<Event> evs = LocalModel.instance.events;
											Event e = evs[evs.length-1-(i/2).floor()];
											EventId id = e.id();
											var err = errs[id];
											bool deleted = value.deletes.contains(id);
											return ListTile(
												onLongPress: () {
													value.appendAndSync([], [id]);
												},
												leading: Text(unixHMS(e.time)),
												title: Text(e.runtimeType.toString()),
												subtitle: Text(e.toString(), overflow: TextOverflow.fade),
												trailing: err != null
													? Column(
														children: [
															const Icon(Icons.warning),
															Text(err.description),
														]
													)
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
		);
}

bool adminOnly(Event e) =>
	e is InitEvent ||
	e is ChangeCategoryEvent;
