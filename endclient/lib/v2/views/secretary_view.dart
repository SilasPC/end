import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/v2/app_bars/side_bar.dart';
import 'package:esys_client/v2/app_bars/top_bar.dart';
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
      LayoutBuilder(builder: (context, constraints) {
        var rem = constraints.maxWidth - eqCardWidth - notifCardWidth;
        var showNotifs = rem > 1.5 * maxGridCardWidth;
        var stacked = constraints.maxWidth < eqCardWidth + maxGridCardWidth;

        Widget body;
        if (stacked) {
          var cats = context.watch<LocalModel>().model.categories;
          body = Column(children: [
            SessionSummaryCard(),
            if (cats.isNotEmpty)
              CarouselSlider(
                items: [
                  for (var cat in cats.values) CategoryCard(cat: cat),
                ],
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                ),
              ),
            Expanded(
                child: EquipagesCard(builder: EquipagesCard.withAdminChoices))
          ]);
        } else {
          body = Row(
            children: [
              Expanded(
                child: Column(children: [
                  SessionSummaryCard(),
                  Expanded(
                    child: _catsGrid,
                  )
                ]),
              ),
              const SizedBox(
                width: eqCardWidth,
                child: EquipagesCard(builder: EquipagesCard.withAdminChoices),
              ),
              if (showNotifs)
                const SizedBox(
                  width: notifCardWidth,
                  child: NotificationsCard(),
                )
            ],
          );
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          drawer: SideBar.fromUI(context.watch()),
          drawerEnableOpenDragGesture: false,
          appBar: TopBar(),
          body: body,
        );
      });

  final Widget _catsGrid = LayoutBuilder(builder: (context, constraints) {
    var cats = context.watch<LocalModel>().model.categories;
    var maxEls = constraints.maxWidth / maxGridCardWidth;
    return GridView.count(
      crossAxisCount: max(1, maxEls.floor()),
      children: [
        for (var cat in cats.values) CategoryCard(cat: cat),
      ],
    );
  });
}
