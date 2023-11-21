
import 'package:esys_client/equipage/equipage.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/landing.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/settings.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Landing2 extends StatelessWidget {

	const Landing2({super.key});

	@override
	Widget build(BuildContext context) {

		var model = context.watch<LocalModel>();
		// var conn = context.watch<ServerConnection>();

		var inSession = model.model.rideName != "";

		var body = Container(
			constraints: const BoxConstraints(maxWidth: 400),
			alignment: Alignment.center,
			padding: const EdgeInsets.symmetric(
				vertical: 40,
				horizontal: 60
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				mainAxisAlignment: MainAxisAlignment.start,
				children: [
					Text(
						!inSession
							? "No active session"
							: model.model.rideName,
						style: const TextStyle(
							color: Colors.black,
							fontSize: 20,
							fontWeight: FontWeight.bold
						)		
					),
					ElevatedButton(
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
								.push(MaterialPageRoute(builder: (context) => const LandingPage()));
						},
					),
					SizedBox(height: 10),
					if (inSession) ...[
						Container(
							alignment: Alignment.center,
							padding: const EdgeInsets.symmetric(vertical: 5),
							decoration: BoxDecoration(
								borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
								color: Colors.black38.withAlpha(200),
							),
							child: const Text(
								"Equipages",
								style: TextStyle(
									color: Colors.white,
									fontSize: 25,
									fontWeight: FontWeight.bold,
								)
							)
						),
						Expanded(
							child: ListView(
								children: [
									for (var eq in model.model.equipages.values)
									EquipageTile(
										eq,
										color: Colors.black38.withAlpha(200),
										onTap: () {
											Navigator.of(context)
												.push(MaterialPageRoute(
													builder: (context) => EquipagePage(eq)
												));
										},
									),
								],
							),
						),
						/* Container(
							padding: const EdgeInsets.symmetric(vertical: 5),
							decoration: BoxDecoration(
								borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
								color: Colors.black38.withAlpha(200),
							),
						), */
					]
				],
			)
		);

		return Scaffold(
			appBar: AppBar(
				actions: [
					IconButton(
						icon: const Icon(Icons.settings),
						onPressed: () {
							Navigator.of(context)
								.push(MaterialPageRoute(
									builder: (context) => const SettingsPage(),
								));
						},
					),
					const ConnectionIndicator(),
				]
			),
			body: BackgroundStack(Center(child: body))
		);

	}

}
