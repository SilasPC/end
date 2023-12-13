
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/util/my_icons.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionSummaryCard extends StatelessWidget {

	const SessionSummaryCard({super.key});
	
	@override
	Widget build(BuildContext context) {
		LocalModel model = context.watch();
		return Card(
				child: Column(
					children: [
						...cardHeader(model.model.rideName),
						if (model.model.equipeId case int equipeId)
						IconButton(
							icon: const Icon(MyIcons.equipe),
							onPressed: () {
								var uri = Uri.parse("https://online.equipe.com/da/competitions/$equipeId");
								launchUrl(uri);
							},
						)
					]
				)
		);
	}

}
