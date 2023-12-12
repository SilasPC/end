

import 'package:common/util.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/settings.dart';
import 'package:esys_client/util/submit_button.dart';
import 'package:esys_client/v2/dashboard/component/equipages_card.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:common/models/glob.dart';
import 'package:wakelock/wakelock.dart';
import '../../services/local_model.dart';
import '../../gates/gate_controller.dart';

class GenericGateView extends StatefulWidget {

	final Future<void> Function()? submit;
	final Comparator<Equipage> comparator;
	final bool submitDisabled;
	final Predicate<Equipage> predicate;
	final EquipageTile Function(Equipage) builder;
	const GenericGateView({
		super.key,
		required this.submit,
		this.submitDisabled = false,
		required this.comparator,
		required this.predicate,
		required this.builder,
	});

	@override
	State<GenericGateView> createState() => _TimingListGateViewState();
}

class _TimingListGateViewState extends State<GenericGateView> implements GateState {

	List<Equipage> equipages = [];

	@override
	void dispose() {
		super.dispose();
		Wakelock.disable();
	}
	
	@override
	void initState() {
		super.initState();
	}

	@override
	void refresh() {
		if (!mounted) return;
		setState(() {
			equipages
				..retainWhere(widget.predicate)
				..sort(widget.comparator);
		});
	}
	
	Future<void> submit() async {
		await widget.submit?.call();
		refresh();
	}

	@override
	Widget build(BuildContext context) {
		if (context.read<Settings>().useWakeLock) {
			Wakelock.enable();
		}
		var model = context.watch<LocalModel>();

		Set<Equipage> newEquipages = model.model.equipages.values.where(widget.predicate).toSet();
		Set<Equipage> oldEquipages = equipages.toSet();
		equipages.addAll(newEquipages.difference(oldEquipages));

		return
			Row(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					SizedBox(
						width: 400,
						child: EquipagesCard(
							builder: EquipagesCard.withChevrons,
							// UI: this will move around !!!
							preFilter: (eq) => !equipages.contains(eq),
							filter: (eq) => !widget.predicate(eq),
							onTap: (eq) {
								if (!equipages.contains(eq)) {
									setState(() {
										equipages.add(eq);
									});
								}
							}
						),
					),
					SizedBox(
						width: 400,
						child: Scaffold(
							backgroundColor: Colors.transparent,
							body: Card(
								child: ListView(
									children: [
										...cardHeaderWithTrailing(
											"Timings", [
												/* IconButton(
													icon: Icon(Icons.sort),
													onPressed: refresh,
												), */
												if (widget.submit != null)
												SubmitButton(
													onPressed: submit,
													disabled: widget.submitDisabled,
												),
											]
										),
										for (Equipage eq in equipages)
										widget.builder(eq),
									],
								)
							),
						),
					),
				],
			);
	}

}
