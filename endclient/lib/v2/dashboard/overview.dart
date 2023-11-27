
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:math';

import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/component/category_card.dart';
import 'package:esys_client/v2/dashboard/component/session_summary_card.dart';
import 'package:esys_client/v2/dashboard/component/notifications_card.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double eqCardWidth = 400;
const double notifCardWidth = 250;
const double maxGridCardWidth = 160;

class OverviewView extends StatelessWidget {

	OverviewView({super.key});

	@override
	Widget build(BuildContext context) =>
		LayoutBuilder(
			builder: (context, constraints) {
				var rem = constraints.maxWidth - eqCardWidth - notifCardWidth;
				var showNotifs = rem > 1.5 * maxGridCardWidth;
				var stacked = constraints.maxWidth < eqCardWidth + maxGridCardWidth;

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
						SizedBox(
							width: eqCardWidth,
							child: EquipagesCard(
								builder: EquipagesCard.withAdminChoices
							),
						),
						if (showNotifs)
						SizedBox(
							width: notifCardWidth,
							child: NotificationsCard(),
						)
					],
				);
			},
		);

	final Widget _catsGrid = LayoutBuilder(
		builder: (context, constraints) {
			var cats = context.watch<LocalModel>().model.categories;
			var maxEls = constraints.maxWidth / maxGridCardWidth;
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
