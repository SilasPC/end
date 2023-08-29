
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
				var equipages = widget.cat.equipages.toList()..sort(Equipage.byRank);
				return Container(
					padding: const EdgeInsets.all(10),
					child: Column(
						children: [
							Card(
								child: Column(
									children: [
										cardHeader(context, widget.cat.name, color: const Color.fromARGB(255, 98, 85, 115)),
										const SizedBox(height: 7,),
										Text("Loops: ${widget.cat.loops.map((l) => l.distance).join(", ")}"),
										const SizedBox(height: 7,)
									],
								)
							),
							// TODO: make list not automatically reorder on update
							Expanded(
								child: ListView.builder(
									itemCount: equipages.length,
									itemBuilder: (context, i) {
										var eq = equipages[i];
										return Card(
											child: EquipageTile(
													eq,
													onTap: () =>
														Navigator.push(context, MaterialPageRoute(
															builder: (_) => EquipagePage(eq)
														)),
													leading: CircleAvatar(
														child: eq.isOut ? const Text("DNF") : Text(" ${i+1}."),
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
				switch (value) {
					case 'start-clearance':
						LocalModel.instance.addSync([
							StartClearanceEvent(LocalModel.instance.author, nowUNIX(), [eq.eid])
						]);
						break;
					case "disqualify":
						showInputModal(
							context,
							'Enter disqualification reason',
							(reason) {
								LocalModel.instance.addSync([
									DisqualifyEvent(LocalModel.instance.author, nowUNIX(), eq.eid, reason),
								]);
							}
						);
						break;
					case "retire":
						LocalModel.instance.addSync([
							RetireEvent(LocalModel.instance.author, nowUNIX(), eq.eid)
						]);
						break;
					case "change-category":
						showChoicesModal(
							context,
							LocalModel.instance.model.categories.keys.toList(),
							(cat) {
								LocalModel.instance.addSync([
									ChangeCategoryEvent(LocalModel.instance.author, nowUNIX(), eq.eid, cat)
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
