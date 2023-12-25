import 'package:common/models/Equipage.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:esys_client/v2/views/exam_gate/exam_gate_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExamGateToolbar extends StatefulWidget {
  final bool selectorEnabled;
  final Equipage? equipage;
  final void Function(Equipage) onChange;

  const ExamGateToolbar(
      {super.key,
      required this.selectorEnabled,
      this.equipage,
      required this.onChange});

  @override
  State<ExamGateToolbar> createState() => _TimingGateToolbarState();
}

class _TimingGateToolbarState extends State<ExamGateToolbar> {
  Equipage? equipage;

  @override
  void initState() {
    super.initState();
    equipage = widget.equipage;
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          if (widget.equipage case Equipage eq)
            Expanded(child: EquipageTile(eq))
          else
            Text(
              "No equipage selected",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget sheet(BuildContext context) {
    return Navigator(
        onGenerateInitialRoutes: (context, routeSettings) => [
              MaterialPageRoute(builder: _selectView),
              if (equipage case Equipage eq)
                MaterialPageRoute(builder: (context) => _infoView(context, eq))
            ]);
  }

  Widget _selectView(BuildContext context) {
    return ListView(
      children: [
        for (var eq in context.watch<LocalModel>().model.equipages.values)
          EquipageTile(
            eq,
            trailing: [
              IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () {
                    equipage = eq;
                    widget.onChange(eq);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => _infoView(context, eq)));
                  })
            ],
          )
      ],
    );
  }

  Widget _infoView(BuildContext context, Equipage eq) {
    return Column(
      children: [
        EquipageTile(
          eq,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Expanded(
          child: ListView(children: [
            ListTile(
              title: const Text("Loop"),
              trailing: Text(
                  "${eq.currentLoopOneIndexed ?? "-"}/${eq.category.loops.length}"),
            ),
            ...loopCards(eq),
          ]),
        )
      ],
    );
  }
}
