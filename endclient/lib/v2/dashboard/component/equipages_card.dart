// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/util/secretary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EquipagesCard extends StatelessWidget {
	const EquipagesCard({
		super.key,
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			color: Colors.black26,
			child: SizedBox(
				width: 400,
				child: Builder(
					builder: (context) {
						LocalModel model = context.watch();
						return ListView(
							children: [
								Container(
									alignment: Alignment.center,
									padding: const EdgeInsets.all(8),
									child: Text(
										"Equipages",
										style: TextStyle(
											fontSize: 20
										)
									),
								),
								Divider(),
								// UI: sort by eid
								for (var (i, eq) in model.model.equipages.values.indexed)
								EquipageTile(
									eq,
									trailing: [equipageAdministrationPopupMenuButton(eq, context)],
									color: i % 2 == 0 ? Color.fromARGB(5, 255, 255, 255) : null),
							],
						);
					}
				)
			)
		);
	}
}
