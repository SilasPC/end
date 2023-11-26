
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:math';

import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/component/category_card.dart';
import 'package:esys_client/v2/dashboard/component/session_summary_card.dart';
import 'package:esys_client/v2/dashboard/component/notifications_card.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverviewView extends StatelessWidget {
	const OverviewView({super.key});

	@override
	Widget build(BuildContext context) =>
		Row(
			children: [
				Expanded(
					child: Column(
						children: [
							SessionSummaryCard(),
							Expanded(
								child: LayoutBuilder(
									builder: (context, constraints) {
										const maxWidth = 160;
										var cats = context.watch<LocalModel>().model.categories;
										var maxEls = constraints.maxWidth / maxWidth;
										return GridView.count(
											crossAxisCount: max(1, maxEls.floor()),
											children: [
												for (var cat in cats.values)
												CategoryCard(cat: cat),
											],
										);
									}
								)
							)
						]
					),
				),
				EquipagesCard(builder: EquipagesCard.withAdminChoices),
				NotificationsCard()
			],
		);

}
