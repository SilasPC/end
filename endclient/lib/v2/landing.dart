

import 'package:animations/animations.dart';
import 'package:common/p2p/Manager.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/landing.dart';
import 'package:esys_client/testing.dart';
import 'package:esys_client/v2/dashboard/views/settings_view.dart';
import 'package:esys_client/v2/equipage_page.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/dashboard.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

class Landing extends StatefulWidget {

	const Landing({super.key});

	@override
	State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {

	@override
	void initState() {
		super.initState();
		_init();
	}

	void _init() async {
		var nav = Navigator.of(context);
		var isService = context.read<IdentityService>();
		await context.read<PeerManager>().ready;
		if (await isService.isAuthorized()) {
			nav.push(MaterialPageRoute(
				builder: (context) => const Dashboard()
			));
		}
		FlutterNativeSplash.remove();
	}

	@override
	Widget build(BuildContext context) {

		LocalModel model = context.watch();
		var inSession = model.model.rideName.isNotEmpty;

		return Material(
			child: Container(
				decoration: backgroundGradient,
				child: Wrap(
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
                                       labelIconButton("TESTING", Icons.login, onPressed: () {
														Navigator.of(context)
															.push(MaterialPageRoute(builder: (context) => const TestingPage()));
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
				)
			)
		);
	}

}
