
import 'package:common/models/glob.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_model.dart';
import '../equipage/equipage_tile.dart';

class EquipageSelectorDrawer extends StatefulWidget {

	final double heightFactor;
	final void Function(Equipage) onTab;

	const EquipageSelectorDrawer({super.key, required this.onTab, this.heightFactor = 0.7});

	@override
	State<EquipageSelectorDrawer> createState() => _EquipageSelectorDrawerState();
}

class _EquipageSelectorDrawerState extends State<EquipageSelectorDrawer> {

	bool shown = false;

	@override
	Widget build(BuildContext context) =>
		BottomAppBar(
			child: !shown
				? ElevatedButton(
					child: Text(shown ? "Hide more" : "Show more"),
					onPressed: () => setState(() {
						shown ^= true;
					}),
				)
				:
			ConstrainedBox(
				constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * widget.heightFactor),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						ElevatedButton(
							child: Text(shown ? "Hide more" : "Show more"),
							onPressed: () => setState(() {
								shown ^= true;
							}),
						),
						Expanded(
							child: ListView(
								children: [
									for (var eq in context.watch<LocalModel>().model.equipages.values)
									EquipageTile(eq, trailing: [
										IconButton(
											icon: const Icon(Icons.add),
											onPressed: () => widget.onTab(eq),
										)
									],)
								],
							),
						),
					],
				)
			)
		);
}
