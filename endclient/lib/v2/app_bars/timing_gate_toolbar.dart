import 'package:common/models/Equipage.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimingGateToolbar extends StatefulWidget {
  final bool selectorSheetEnabled;

  final List<Equipage> equipages;
  final void Function()? onPressed;
  final void Function(Equipage) onAdd;
  final void Function() onRefresh;

  const TimingGateToolbar(
      {super.key,
      this.onPressed,
      required this.onRefresh,
      required this.equipages,
      required this.onAdd,
      required this.selectorSheetEnabled});

  @override
  State<TimingGateToolbar> createState() => _TimingGateToolbarState();
}

class _TimingGateToolbarState extends State<TimingGateToolbar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: [
          if (widget.selectorSheetEnabled)
            IconButton(
              icon: Icon(Icons.view_list),
              onPressed: () {
                // UI: sheet not rebuilt when toolbar rebuilds
                showModalBottomSheet(
                  context: context,
                  builder: sheet,
                );
              },
            ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: widget.onRefresh,
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: widget.onPressed,
          ),
        ],
      ),
    );
  }

  Widget sheet(BuildContext context) {
    return SizedBox(
      height: 400,
      child: ListView(
        children: [
          for (var eq in context.watch<LocalModel>().model.equipages.values)
            EquipageTile(
              eq,
              trailing: [
                widget.equipages.contains(eq)
                    ? IconButton(icon: Icon(Icons.check), onPressed: null)
                    : IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => widget.onAdd(eq),
                      )
              ],
            )
        ],
      ),
    );
  }
}
