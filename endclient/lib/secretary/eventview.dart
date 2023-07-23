
import 'package:common/AbstractEventModel.dart';
import 'package:common/Event.dart';
import 'package:common/util.dart';
import 'package:flutter/material.dart';

import '../LocalModel.dart';

class EventView extends StatefulWidget {
	const EventView({super.key});
	@override
	State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
	bool Function(Event)? filterFn;

	Widget header() =>
		Card(
			child: DropdownButton<String>(
				value: "all",
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
						switch (value) {
							case "all":
								filterFn = null;
								break;
							case "admin":
								filterFn = adminOnly;
								break;
							default:
								unimpl(); // todo for each equipage (requires event.affectsEquipage)
						}
					}),
			),
		);
	
	@override
	Widget build(BuildContext context) =>
		Container(
			padding: const EdgeInsets.all(10),
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
		);
}

bool adminOnly(Event e) =>
	e is InitEvent ||
	e is ChangeCategoryEvent;