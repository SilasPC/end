
import 'package:common/util.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:esys_client/util/submit_button.dart';
import 'package:flutter/material.dart';
import 'package:common/models/glob.dart';
import 'package:provider/provider.dart';

import '../LocalModel.dart';

class GenericGate extends StatefulWidget {

   final Widget title;
	final Future<void> Function() onSubmit;
	final bool submitDisabled;
	final Comparator<Equipage> comparator;
	final Predicate<Equipage> predicate;
	final Widget Function(Equipage, bool) builder;

	const GenericGate({super.key, required this.title, required this.comparator, required this.predicate, required this.onSubmit, this.submitDisabled = false, required this.builder});

	@override
	State<GenericGate> createState() => _GenericGateState();
}

class _GenericGateState extends State<GenericGate> {

	List<Equipage> equipages = [];

	Future<void> submit(BuildContext ctx) async {
		await widget.onSubmit();
		if (mounted) {
         setState(() {
            equipages
               ..retainWhere(widget.predicate)
               ..sort(widget.comparator);
         });
      }
	}

	Widget buildList(BuildContext ctx) =>
		Consumer<LocalModel>(
			builder: (context, model, child) {

				Set<Equipage> newEquipages =
					model.model.equipages.values
						.where(widget.predicate)
						.toSet();

				
				Set<Equipage> oldEquipages = equipages.toSet();

				equipages.addAll(newEquipages.difference(oldEquipages));

				return ListView(
               children:
                  equipages.map((e) => widget.builder(e, widget.predicate(e)))
                  .toList()
				);
			}
		);

	@override
	Widget build(BuildContext ctx) =>
		Scaffold(
			appBar: AppBar(
				actions: [
					const ConnectionIndicator(),
					IconButton(
						onPressed: () => setState(() {
							equipages
								..retainWhere(widget.predicate)
								..sort(widget.comparator);
						}),
						icon: const Icon(Icons.sort),
					),
					SubmitButton(
						onPressed: () => submit(ctx),
						disabled: widget.submitDisabled,
					)
				],
				title: widget.title,
			),
			body: buildList(ctx),
		);

}
