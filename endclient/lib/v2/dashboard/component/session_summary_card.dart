// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionSummaryCard extends StatelessWidget {

	const SessionSummaryCard({super.key});
	
	@override
	Widget build(BuildContext context) {
		LocalModel model = context.watch();
		return SizedBox(
			height: 100,
			child: Card(
				child: Column(
					children: [
						...cardHeader(model.model.rideName),
					]
				)
			),
		);
	}

}
