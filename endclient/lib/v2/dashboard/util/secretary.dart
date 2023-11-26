
import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util/unix.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/input_modals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget equipageAdministrationPopupMenuButton(Equipage eq, BuildContext context) =>
	PopupMenuButton<String>(
		splashRadius: 16,
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
