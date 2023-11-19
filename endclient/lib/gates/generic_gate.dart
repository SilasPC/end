
import 'package:esys_client/util/text_clock.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:wakelock/wakelock.dart';
import '../settings_provider.dart';
import 'gate_controller.dart';
import '../util/connection_indicator.dart';
import '../util/equipage_selector_drawer.dart';
import '../util/submit_button.dart';
import '../local_model/LocalModel.dart';

class GenericGate extends StatefulWidget {

   final Widget title;
	final Future<void> Function()? onSubmit;
	final bool submitDisabled;
	final Comparator<Equipage> comparator;
	final Predicate<Equipage> predicate;
	final Widget Function(Equipage, bool) builder;
	final GateController? controller;

	const GenericGate({
		super.key,
		required this.title,
		required this.comparator,
		required this.predicate,
		required this.onSubmit,
		this.submitDisabled = false,
		this.controller,
		required this.builder
	});

	@override
	State<GenericGate> createState() => _GenericGateState();
}

class _GenericGateState extends State<GenericGate> implements GateState {

	@override
	void dispose() {
		super.dispose();
		Wakelock.disable();
	}

	@override
	void initState() {
		super.initState();
		widget.controller?.state = this;
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

	List<Equipage> equipages = [];

	Future<void> submit(BuildContext ctx) async {
		await widget.onSubmit?.call();
		refresh();
	}

	Widget buildList(BuildContext context) {
		var model = context.watch<LocalModel>();

		// no custom hash impl, refresh to point to new objects
		// representing the equipages for ptr hash/eq
		// maybe use id instead (but what about widget.predicate /.comparator?)
		equipages = equipages
			.map((e) => model.model.equipages[e.eid]!)
			.toList();

		Set<Equipage> newEquipages =
			model.model.equipages.values
				.where(widget.predicate)
				.toSet();

		Set<Equipage> oldEquipages = equipages.toSet();

		equipages.addAll(newEquipages.difference(oldEquipages));

		return ListView(
			children:
				<Widget>[
					FittedBox(
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 8),
							child: TextClock(),
						)
					)
				].followedBy(
					equipages.map((e) => widget.builder(e, widget.predicate(e)))
				)
				.toList()
		);

	}

	@override
	Widget build(BuildContext context) {
		if (context.read<Settings>().useWakeLock) {
			Wakelock.enable();
		}
		return Scaffold(
			// backgroundColor: Colors.transparent,
			appBar: AppBar(
				actions: [
					const ConnectionIndicator(),
					IconButton(
						onPressed: refresh,
						icon: const Icon(Icons.sort),
					),
					if (widget.onSubmit != null)
					SubmitButton(
						onPressed: () => submit(context),
						disabled: widget.submitDisabled,
					)
				],
				title: widget.title,
			),
			body: buildList(context),
			bottomNavigationBar: EquipageSelectorDrawer(
				onTab: (eq) {
					if (!equipages.contains(eq)) {
						setState(() => equipages.add(eq));
					}
				}
			),
		);
	}

}
