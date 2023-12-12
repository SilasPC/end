

import 'package:animations/animations.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/landing.dart';
import 'package:esys_client/v2/equipage_page.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/dashboard.dart';
import 'package:esys_client/v2/dashboard/settings_view.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class Landing extends StatelessWidget {

	const Landing({super.key});

	@override
	Widget build(BuildContext context) => 
		FutureBuilder(
			future: context.read<LocalModel>().manager.ready
				.then((_) => context.read<IdentityService>().isAuthorized()),
			builder: (context, snapshot) {
				Widget body;
				if (snapshot.data == false) {
						var model = context.watch<LocalModel>();
						// var conn = context.watch<ServerConnection>();
						var inSession = model.model.rideName != "";
						body = _view(context, inSession, model);
				} else {
					if (snapshot.data == true) {
						Navigator.push(context, MaterialPageRoute(
							builder: (context) => const Dashboard()
						));
					}
					body = const Center(
						child: SpinKitCubeGrid(
							color: primaryColor,
						),
					);
				}
				return Material(
					child: Container(
						decoration: backgroundGradient,
						child: body,
					)
				);
			}
		);

	Widget _view(BuildContext context, bool inSession, LocalModel model) =>
		Wrap(
			alignment: WrapAlignment.center,
			runAlignment: WrapAlignment.center,
			crossAxisAlignment: WrapCrossAlignment.center,
			children: [
				SizedBox(
					width: 400,
					child: Card(
						child: Column(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								...cardHeader(
										inSession
											? model.model.rideName
											: "No active session",
								),
								Padding(
									padding: const EdgeInsets.all(10),
									child: Wrap(
										spacing: 10,
										runSpacing: 10,
										alignment: WrapAlignment.spaceEvenly,
										children: [
											labelIconButton("LOGIN", Icons.login, onPressed: () {
												Navigator.of(context)
													.push(MaterialPageRoute(builder: (context) => const Dashboard()));
											}),
											labelIconButton("SETTINGS", Icons.settings, onPressed: () {
												showModal(
													context: context,
													builder: (context) => const SettingsView(mainAxisAlignment: MainAxisAlignment.center),
												);
											}),
											labelIconButton("OLD", Icons.login, onPressed: () {
												Navigator.of(context)
													.push(MaterialPageRoute(builder: (context) => const LandingPage()));
											}),
										]
									),
								)
							]
						)
					),
				),
				SizedBox(
					height: MediaQuery.sizeOf(context).height - 250, // IGNORED: UI: alternative to -250 ?
					width: 400,
					child: EquipagesCard(
						builder: EquipagesCard.withChevrons,
						onTap: (eq) => Navigator.of(context)
							.push(MaterialPageRoute(builder: (context) => EquipagePage(eq))),
					),
				)
			],
		);

}
