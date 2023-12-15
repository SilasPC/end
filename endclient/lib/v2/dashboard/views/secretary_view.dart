

import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/v2/dashboard/component/category_card.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/util/my_icons.dart';
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
					var cats = context.watch<LocalModel>().model.categories;
					return Column(
						children: [
							SessionSummaryCard(),
                     if (cats.isNotEmpty)
							CarouselSlider(
								items: [
									for (var cat in cats.values)
									Stack(
										alignment: Alignment.bottomRight,
										children: [
											CategoryCard(cat: cat),
											Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													if (cat.equipeId case int _)
													IconButton(
														style: IconButton.styleFrom(
															backgroundColor: primaryColor,
														),
														icon: Icon(MyIcons.equipe, color: secondaryColor),
														onPressed: () {},
													),
													const SizedBox(width: 16,),
													IconButton(
														style: IconButton.styleFrom(
															backgroundColor: primaryColor,
														),
														icon: Icon(MyIcons.trophy, color: secondaryColor),
														onPressed: () {},
													),
													const SizedBox(width: 32,),
												],
											),
										],
									)
								],
								options: CarouselOptions(
									height: 200,
									enlargeCenterPage: true,
								),
							),
							Expanded(
								child: EquipagesCard(builder: EquipagesCard.withAdminChoices)
							)
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
