
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/EquipeIcons.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../LocalModel.dart';
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
				var rankOf = sortIndexMap(eqs, Equipage.byRank);
				return Container(
					padding: const EdgeInsets.all(10),
					child: Column(
						children: [
							Card(
								child: Column(
									children: [
										cardHeader(context, widget.cat.name, color: const Color.fromARGB(255, 98, 85, 115)),
										// Text("8-16 km/h"),
										Padding(
											padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
											child: Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													// UI: clear/free/ideal min/max time/speed status
													// UI: loop cards (#riders / color?)
													for (var loop in widget.cat.loops)
													Container(
														alignment: Alignment.center,
														padding: const EdgeInsets.all(10),
														margin: const EdgeInsets.symmetric(horizontal: 4),
														decoration: const BoxDecoration(
															borderRadius: BorderRadius.all(Radius.circular(10)),
															color: Color.fromARGB(255, 146, 119, 68),
														),
														child: Text("${loop.distance}km"),
													),
													const Spacer(),
													/* if (widget.cat.isEnded())
													IconButton(
														icon: const Icon(Icons.)
													) */
													if (widget.cat.equipeId != null)
													IconButton(
														icon: const Icon(EquipeIcons.logo),
														onPressed: () {
															var uri = Uri.parse("https://online.equipe.com/da/class_sections/${widget.cat.equipeId}");
															launchUrl(uri);
														},
													),
												],
											),
										)
									],
								)
							),
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
														child: eq.isOut ? const Text("DNF") : Text(" ${rankOf[i]+1}."),
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
					default:
						unimpl(value);
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
