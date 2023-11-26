// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:common/models/glob.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/util/chip_strip.dart';
import 'package:esys_client/v2/dashboard/util/secretary.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EquipagesCard extends StatefulWidget {

	static double width = 400;

	final EquipageTile Function(BuildContext, Equipage, Color?) builder;
	
	const EquipagesCard({
		super.key,
		this.builder = EquipagesCard.withPlainTiles,
	});

	@override
	State<EquipagesCard> createState() => _EquipagesCardState();

	static EquipageTile withPlainTiles(BuildContext context, Equipage eq, Color? color) =>
		EquipageTile(
			eq,
			color: color,
		);

	static EquipageTile withAdminChoices(BuildContext context, Equipage eq, Color? color) =>
		EquipageTile(
			eq,
			trailing: [equipageAdministrationPopupMenuButton(eq, context)],
			color: color,
		);

}

class _EquipagesCardState extends State<EquipagesCard> {

	Category? cat;

	@override
	Widget build(BuildContext context) {
		return Card(
			color: Colors.black26,
			child: SizedBox(
				width: EquipagesCard.width,
				child: Builder(
					builder: (context) {
						LocalModel model = context.watch();
						return ListView(
							children: [
								Container(
									alignment: Alignment.center,
									padding: const EdgeInsets.all(8),
									child: Text(
										"Equipages",
										style: TextStyle(
											fontSize: 20
										)
									),
								),
								Divider(),
								ChipStrip(
									chips: [
										for (var cat in model.model.categories.values)
										ChoiceChip(
											label: Text(cat.name),
											selected: cat == this.cat,
											selectedColor: Colors.white24,
											onSelected: (sel) => setState(() {
												this.cat = sel ? cat : null;
											})
										)
									]
								),
								// UI: sort by eid
								for (var (i, eq) in model.model.equipages.values.indexed)
								if (cat == null || eq.category == cat)
								widget.builder(context, eq, i % 2 == 0 ? Color.fromARGB(5, 255, 255, 255) : null)
							],
						);
					}
				)
			)
		);
	}

}
