
import 'package:common/AbstractEventModel.dart';
import 'package:common/EnduranceEvent.dart';
import 'package:common/util.dart';
import 'package:flutter/material.dart';

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
								filterFn = (e) => e.affectsEquipage(int.parse(value!));
						}
					}),
			),
		);
	
	@override
	Widget build(BuildContext context) =>
		Container(
			padding: const EdgeInsets.all(10),
			child: Column(
				children: [
					header(),
					Expanded(
						child: Card(
							child: ListView.builder(
								itemCount: LocalModel.instance.events.length * 2,
								itemBuilder: (context, i) {
									if (i % 2 == 1) return const Divider();
									List<Event> evs = LocalModel.instance.events;
									Event e = evs[evs.length-1-(i/2).floor()];
									return ListTile(
										leading: Text(unixHMS(e.time)),
										title: Text(e.runtimeType.toString()),
										subtitle: Text(e.toString(), overflow: TextOverflow.fade),
									);
								},
							),
						),
					)
				],
			)
		);
}

bool adminOnly(Event e) =>
	e is InitEvent ||
	e is ChangeCategoryEvent;
