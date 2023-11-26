
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

	OverviewView({super.key});

	@override
	Widget build(BuildContext context) =>
		LayoutBuilder(
			builder: (context, constraints) {
				
				const maxWidth = 160;

				var rem = constraints.maxWidth - EquipagesCard.width - NotificationsCard.width;
				var showNotifs = rem > 1.5 * maxWidth;
				var stacked = constraints.maxWidth < EquipagesCard.width + maxWidth;

				if (stacked) {
					return Column(
						children: [
							SessionSummaryCard(),
							/* Expanded( // UI: don't remember how to do this
								child: _catsGrid,
							), */
							Expanded(child:EquipagesCard(builder: EquipagesCard.withAdminChoices))
						]
					);
				}

				return Row(
					children: [
						Expanded(
							child: Column(
								children: [
									SessionSummaryCard(),
									Expanded(
										child: _catsGrid,
									)
								]
							),
						),
						EquipagesCard(builder: EquipagesCard.withAdminChoices),
						if (showNotifs)
						NotificationsCard(),
					],
				);
			},
		);

	final Widget _catsGrid = LayoutBuilder(
		builder: (context, constraints) {
			var cats = context.watch<LocalModel>().model.categories;
			var maxEls = constraints.maxWidth / 160;
			return GridView.count(	
				crossAxisCount: max(1, maxEls.floor()),
				children: [
					for (var cat in cats.values)
					CategoryCard(cat: cat),
				],
			);
		}
	);

}
