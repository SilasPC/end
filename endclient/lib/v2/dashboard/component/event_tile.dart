
import 'package:common/EnduranceEvent.dart';
import 'package:common/event_model/Event.dart';
import 'package:common/models/Model.dart';
import 'package:common/util.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
										var updated = (event as EnduranceEvent)
											.copyWithTime(toUNIX(dt));
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
					/* SizedBox(
						width: 50,
						child: Text(
							event.author, 
							textAlign: TextAlign.center, 
							maxLines: 1, overflow: TextOverflow.ellipsis, 
							// style: const TextStyle(color: Colors.grey)
						),
					) */
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
