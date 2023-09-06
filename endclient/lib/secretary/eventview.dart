
import 'package:common/EnduranceEvent.dart';
import 'package:common/EventModel.dart';
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
	bool Function(Event<Model>)? filterFn;

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
					for (var eq in LocalModel.instance.model.equipages.values)
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
	Widget build(BuildContext context) =>
		Consumer<LocalModel>(
			builder: (context, value, child) {

				// UI: index here does not correspond to filtered index
				Map<int, EventError> errs = {};
				for (var err in value.model.errors) {
					errs[err.causedBy] = err;
				}
				for (var err in value.model.warnings) {
					errs[err.causedBy] = err;
				}

				var evs = filterFn != null ? value.events.iteratorOrdered.where(filterFn!).toList() : value.events.iteratorOrdered.toList();

				return Container(
					padding: const EdgeInsets.all(10),
					child: Column(
						children: [
							header(),
							Expanded(
								child: Card(
									child: ListView.separated(
										itemCount: evs.length,
										separatorBuilder: (context, _) => const Divider(),
										itemBuilder: (context, i) {
                                 var evIdx = evs.length - 1 - i;
											var e = evs[evIdx];
											var err = errs[evIdx];
											bool deleted = value.deletes.contains(e);
											return ListTile(
												onLongPress: () {
													value.addSync([], [e]);
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
