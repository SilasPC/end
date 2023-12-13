

import 'dart:math';

import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/dashboard/component/category_card.dart';
import 'package:esys_client/v2/dashboard/component/session_summary_card.dart';
import 'package:esys_client/v2/dashboard/component/notifications_card.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double eqCardWidth = 400;
const double notifCardWidth = 250;
const double maxGridCardWidth = 160;

class SecretaryView extends StatelessWidget {

	SecretaryView({super.key});

	@override
	Widget build(BuildContext context) =>
		LayoutBuilder(
			builder: (context, constraints) {
				var rem = constraints.maxWidth - eqCardWidth - notifCardWidth;
				var showNotifs = rem > 1.5 * maxGridCardWidth;
				var stacked = constraints.maxWidth < eqCardWidth + maxGridCardWidth;

				if (stacked) {
					return ListView(
						children: [
							const Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									SessionSummaryCard(),
									Expanded(
										child: EquipagesCard(builder: EquipagesCard.withAdminChoices),
									),
								],
							),
							SizedBox(
								height: constraints.maxHeight,
								child: _catsGrid
							),
						],
					);
				}

				return Row(
					children: [
						Expanded(
							child: Column(
								children: [
									const SessionSummaryCard(),
									Expanded(
										child: _catsGrid,
									)
								]
							),
						),
						const SizedBox(
							width: eqCardWidth,
							child: EquipagesCard(
								builder: EquipagesCard.withAdminChoices
							),
						),
						if (showNotifs)
						const SizedBox(
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
