// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/util/MyIcons.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionSummaryCard extends StatelessWidget {

	static double height = 100;

	const SessionSummaryCard({super.key});
	
	@override
	Widget build(BuildContext context) {
		LocalModel model = context.watch();
		return SizedBox(
			height: height,
			child: Card(
				child: Column(
					children: [
						...cardHeader(model.model.rideName),
						if (model.model.equipeId case int equipeId)
						IconButton(
							icon: Icon(MyIcons.equipe),
							onPressed: () {
								var uri = Uri.parse("https://online.equipe.com/da/competitions/$equipeId");
								launchUrl(uri);
							},
						)
					]
				)
			),
		);
	}

}
