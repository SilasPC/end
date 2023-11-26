
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/equipage/equipage.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/landing.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/settings.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/util.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Landing2 extends StatelessWidget {

	const Landing2({super.key});

	@override
	Widget build(BuildContext context) {

		var model = context.watch<LocalModel>();
		// var conn = context.watch<ServerConnection>();

		var inSession = model.model.rideName != "";

		return Material(
			child: Wrap(
				alignment: WrapAlignment.center,
				runAlignment: WrapAlignment.center,
				crossAxisAlignment: WrapCrossAlignment.center,
				children: [
					SizedBox(
						height: 200,
						width: 400,
						child: Card(
							color: Colors.black26,
							child: Column(
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: [
									Container(
										alignment: Alignment.center,
										padding: const EdgeInsets.all(8),
										child: Text(
											inSession
												? model.model.rideName
												: "No active session",
											style: TextStyle(
												fontSize: 20
											)
										),
									),
									Divider(),
									Center(
										child: ElevatedButton(
											style: ElevatedButton.styleFrom(backgroundColor: Colors.black38.withAlpha(200)),
											child: const Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Text("LOGIN  "),
													Icon(Icons.login),
												],
											),
											onPressed: () {
												Navigator.of(context)
													.push(MaterialPageRoute(builder: (context) => const Dashboard()));
											},
										),
									),
								]
							)
						),
					),
					SizedBox(
						height: MediaQuery.sizeOf(context).height - 250, // UI: alternative to -250 ?
						child: EquipagesCard(
							builder: (context, eq, color) =>
								EquipageTile(
									eq,
									trailing: [Icon(Icons.chevron_right)],
									color: color,
									/* onTap: () {
										Navigator.of(context)
											.push(MaterialPageRoute(
												builder: (context) => EquipagePage(eq)
											));
									} */
								),
						),
					)
				],
			)
		);

	}

}
