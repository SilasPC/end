// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/consts.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsCard extends StatelessWidget {

	const NotificationsCard({
		super.key,
	});

	@override
	Widget build(BuildContext context) {
		LocalModel model = context.watch();
		return Card(
			child: Column(
				children: [
					...cardHeader("Notifications"),
					if (model.model.errors.isEmpty)
					emptyListText("No notifications"),
					/* Container(
						decoration: BoxDecoration(
							border: Border.all(
								color: Colors.green,
							),
							borderRadius: BorderRadius.circular(8)
						),
						child: ListTile(
							title: Text("MA finished!"),
							subtitle: Text("Results available"),
							trailing: IconButton(
								splashRadius: splashRadius,
								color: Colors.white30,
								icon: Icon(Icons.close),
								onPressed: () {},
							),
						),
					), */
					for (var err in model.model.errors)
					ListTile(
						title: Text("Warning"),
						subtitle: Text(err.description),
						trailing: IconButton(
							splashRadius: splashRadius,
							color: Colors.white30,
							icon: Icon(Icons.close),
							onPressed: () {},
						),
					),
				],
			),
		);
	}
}
