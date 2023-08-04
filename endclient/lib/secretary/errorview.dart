
import 'package:common/AbstractEventModel.dart';
import 'package:common/Event.dart';
import 'package:common/models/EventError.dart';
import 'package:flutter/material.dart';

import '../LocalModel.dart';

class ErrorView extends StatefulWidget {
	const ErrorView({super.key});
	@override
	State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
	
	@override
	Widget build(BuildContext context) =>
		Container(
			padding: const EdgeInsets.all(10),
			child: Card(
				child: ListView.builder(
					itemCount: LocalModel.instance.model.errors.length * 2,
					itemBuilder: (context, i) {
						if (i % 2 == 1) return const Divider();
						List<EventError> evs = LocalModel.instance.model.errors;
						EventError e = evs[evs.length-1-(i/2).floor()];
						return ListTile(
							title: Text(e.description, overflow: TextOverflow.fade),
							subtitle: Text(e.causedBy.toString()),
						);
					},
				),
			),
		);
}

bool adminOnly(Event e) =>
	e is InitEvent ||
	e is ChangeCategoryEvent;
