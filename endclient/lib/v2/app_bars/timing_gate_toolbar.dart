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
  PersistentBottomSheetController? ctrl;

  @override
  Widget build(BuildContext context) {
    if (!widget.selectorSheetEnabled) {
      ctrl?.close();
      ctrl = null;
    }

    return BottomAppBar(
      child: Row(
        children: [
          if (widget.selectorSheetEnabled)
            IconButton(
              icon: Icon(Icons.view_list),
              onPressed: () async {
                if (ctrl != null) {
                  ctrl!.close();
                  ctrl = null;
                  return;
                }

                // UI: sheet not rebuilt when toolbar rebuilds
                ctrl = showBottomSheet(
                  context: context,
                  builder: sheet,
                );
                await ctrl!.closed;
                ctrl = null;
              },
            ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: widget.onPressed,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: widget.onRefresh,
          ),
        ],
      ),
    );
  }

  TapRegion sheet(BuildContext context) {
    return TapRegion(
        onTapOutside: (tap) {
          var h = MediaQuery.sizeOf(context).height;
          if (tap.position.dy < h - 400) {
            ctrl?.close();
          }
        },
        child: SizedBox(
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
        ));
  }
}
