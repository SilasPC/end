
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/results.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/MyIcons.dart';
import 'package:esys_client/util/chip_strip.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../local_model/LocalModel.dart';
import '../equipage/equipage.dart';
import '../equipage/equipage_tile.dart';
import 'util.dart';

class CategoryView extends StatefulWidget {

	final Category cat;
	const CategoryView(this.cat, {super.key});

  @override
	State<StatefulWidget> createState() => CategoryViewState();

}

class CategoryViewState extends State<CategoryView> {

	@override
	Widget build(BuildContext context) =>
		Consumer<LocalModel>(
			builder: (context, model, child) {
				var eqs = widget.cat.equipages;
            var rankOf = Map.fromEntries(widget.cat.rankings());
				return Container(
					padding: const EdgeInsets.all(10),
					child: Column(
						children: [
							CategoryCard(category: widget.cat),
							Expanded(
								child: ListView.builder(
									itemCount: eqs.length,
									itemBuilder: (context, i) {
										var eq = eqs[i];
										return Card(
											child: EquipageTile(
													eq,
													onTap: () =>
														Navigator.push(context, MaterialPageRoute(
															builder: (_) => EquipagePage(eq)
														)),
													leading: CircleAvatar(
														child: eq.isOut ? const Text("DNF") : Text(" ${rankOf[eq]}."),
													),
													trailing: [createEquipagePopupMenu(eq, context)],
												),
										);
									},
								)
							)
						],
					),
				);
			}
		);

	Widget createEquipagePopupMenu(Equipage eq, BuildContext context) =>
		PopupMenuButton<String>(
			onSelected: (value) {
				var model = context.read<LocalModel>();
				var author = context.read<Settings>().author;
				switch (value) {
					case 'start-clearance':
						model.addSync([
							StartClearanceEvent(author, nowUNIX(), [eq.eid])
						]);
						break;
					case "disqualify":
						showInputDialog(
							context,
							'Enter disqualification reason',
							(reason) {
								model.addSync([
									DisqualifyEvent(author, nowUNIX(), eq.eid, reason),
								]);
							}
						);
						break;
					case "retire":
						model.addSync([
							RetireEvent(author, nowUNIX(), eq.eid)
						]);
						break;
					case "change-category":
						showChoicesModal(
							context,
							model.model.categories.keys.toList(),
							(cat) {
								model.addSync([
									ChangeCategoryEvent(author, nowUNIX(), eq.eid, cat)
								]);
							}
						);
						break;
				}
			},
			itemBuilder: (context) => [
				PopupMenuItem(
					enabled: eq.dsqReason == null,
					value: "disqualify",
					child: const Text("Disqualify..."),
				),
				PopupMenuItem(
					enabled: eq.status == EquipageStatus.RESTING,
					value: "retire",
					child: const Text("Retire")
				),
				PopupMenuItem(
					enabled: eq.status == EquipageStatus.WAITING,
					value: "start-clearance",
					child: const Text("Clear for start"),
				),
				PopupMenuItem(
					enabled: eq.status == EquipageStatus.WAITING,
					value: "change-category",
					child: const Text("Change category..."),
				),
			],
		);
}

class CategoryCard extends StatelessWidget {

	const CategoryCard({super.key, required this.category});

	final Category category;

	@override
	Widget build(BuildContext context) {
		context.watch<LocalModel>();

		return Card(
			child: Column(
				children: [
					cardHeader(context, category.name, color: const Color.fromARGB(255, 98, 85, 115)),
					// Text("8-16 km/h"),
					Padding(
						padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Expanded(
									child: ChipStrip(
										chips: [
											// UI: clear/free/ideal min/max time/speed status
											// UI: loop cards (#riders / color?)
											if (category.clearRound)
												const Chip(
													backgroundColor: const Color.fromARGB(255, 146, 119, 68),
													label: Text("Clearround")
												),
											if (category.idealSpeed != null)
												Chip(
													backgroundColor: const Color.fromARGB(255, 146, 119, 68),
													label: Text("Ideal ${category.idealSpeed} km/h")
												),
											if (category.minSpeed != null)
												Chip(
													backgroundColor: const Color.fromARGB(255, 146, 119, 68),
													label: Text("Min. ${category.minSpeed} km/h")
												),
											if (category.maxSpeed != null)
												Chip(
													backgroundColor: const Color.fromARGB(255, 146, 119, 68),
													label: Text("Max. ${category.maxSpeed} km/h")
												),
											Chip(
												backgroundColor: const Color.fromARGB(255, 146, 119, 68),
												label: Text(
													category.loops.map((c) => "${c.distance} km").join(" | ")
												)
											),
										],
									),
								),
								// if (category.isEnded())
								IconButton(
									icon: const Icon(MyIcons.trophy),
                           onPressed: () {
                              Navigator.of(context)
                                 .push(MaterialPageRoute(
                                    builder: (_) => ResultsPage(cat: category)
                                 ));
                           }
								),
								if (category.equipeId != null)
								IconButton(
									icon: const Icon(MyIcons.equipe),
									onPressed: () {
										var uri = Uri.parse("https://online.equipe.com/da/class_sections/${category.equipeId}");
										launchUrl(uri);
									},
								),
							],
						),
					)
				],
			)
		);
	}

}
