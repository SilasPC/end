import 'package:common/EnduranceEvent.dart';
import 'package:common/models/glob.dart';
import 'package:common/util.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/util/chip_strip.dart';
import 'package:esys_client/util/input/input_modals.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:esys_client/equipage/equipage_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EquipagesCard extends StatefulWidget {
  final bool forceFilter;
  final Predicate<Equipage>? filter;
  final EquipageTile Function(BuildContext, EquipagesCard, Equipage, Color?)
      builder;
  final void Function(Equipage)? onTap;
  final String? emptyLabel;

  const EquipagesCard({
    super.key,
    this.builder = EquipagesCard.withPlainTiles,
    this.onTap,
    this.filter,
    this.forceFilter = false,
    this.emptyLabel = "None found",
  });

  @override
  State<EquipagesCard> createState() => _EquipagesCardState();

  static EquipageTile withPlainTiles(BuildContext context, EquipagesCard self,
          Equipage eq, Color? color) =>
      EquipageTile(
        eq,
        color: color,
        onTap: self.onTap != null ? () => self.onTap!(eq) : null,
      );

  static EquipageTile withChevrons(BuildContext context, EquipagesCard self,
          Equipage eq, Color? color) =>
      EquipageTile(
        eq,
        color: color,
        trailing: const [
          Icon(Icons.chevron_right),
        ],
        onTap: self.onTap != null ? () => self.onTap!(eq) : null,
      );

  static EquipageTile withAdminChoices(BuildContext context, EquipagesCard self,
          Equipage eq, Color? color) =>
      EquipageTile(
        eq,
        trailing: [equipageAdministrationPopupMenuButton(eq, context)],
        color: color,
        onTap: self.onTap != null ? () => self.onTap!(eq) : null,
      );
}

class _EquipagesCardState extends State<EquipagesCard> {
  bool filterEnabled = true;
  Category? cat;

  @override
  Widget build(BuildContext context) {
    LocalModel model = context.watch();
    var eqs = model.model.equipages.values;
    var useFilter = filterEnabled || widget.forceFilter;
    if (widget.filter case Predicate<Equipage> filter when useFilter) {
      eqs = eqs.where(filter);
    }
    if (cat case Category cat) {
      eqs = eqs.where((eq) => eq.category == cat);
    }
    return Card(
        // needed because the tiles have a background color
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            ...cardHeaderWithTrailing("Equipages", [
              if (widget.filter != null)
                IconButton(
                  icon: Icon(
                      useFilter ? Icons.filter_list : Icons.filter_list_off),
                  onPressed: widget.forceFilter
                      ? null
                      : () => setState(() => filterEnabled ^= true),
                )
            ]),
            if (widget.filter == null)
              ChipStrip(chips: [
                for (var cat in model.model.categories.values)
                  ChoiceChip(
                      label: Text(cat.name),
                      selected: cat == this.cat,
                      onSelected: (sel) => setState(() {
                            this.cat = sel ? cat : null;
                          }))
              ]),
            /* SearchBar(
						leading: Icon(Icons.search),
						hintText: "awd",
					), */
            Expanded(
                child: ListView(
              children: [
                for (var (i, eq) in eqs.indexed)
                  widget.builder(context, widget, eq,
                      i % 2 == 0 ? Theme.of(context).focusColor : null),
                if (widget.emptyLabel case String label when eqs.isEmpty)
                  emptyListText(label)
              ],
            )),
          ],
        ));
  }
}

Widget equipageAdministrationPopupMenuButton(
        Equipage eq, BuildContext context) =>
    PopupMenuButton<String>(
      splashRadius: splashRadius,
      onSelected: (value) {
        LocalModel model = context.read();
        final author = context.read<IdentityService>().author!;
        switch (value) {
          case 'start-clearance':
            model.addSync([
              StartClearanceEvent(author, nowUNIX(), [eq.eid])
            ]);
            break;
          case "disqualify":
            showInputDialog(context, 'Enter disqualification reason', (reason) {
              model.addSync([
                DisqualifyEvent(author, nowUNIX(), eq.eid, reason),
              ]);
            });
            break;
          case "retire":
            model.addSync([RetireEvent(author, nowUNIX(), eq.eid)]);
            break;
          case "show-info":
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => EquipagePage(eq),
            ));
            break;
          case "change-category":
            showChoicesModal(context, model.model.categories.keys.toList(),
                (cat) {
              model.addSync(
                  [ChangeCategoryEvent(author, nowUNIX(), eq.eid, cat)]);
            });
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: eq.dsqReason == null,
          value: "disqualify",
          child: const Row(children: [
            Icon(Icons.block),
            SizedBox(
              width: 10,
            ),
            Text("Disqualify..."),
          ]),
        ),
        PopupMenuItem(
          enabled: eq.status == EquipageStatus.RESTING,
          value: "retire",
          child: const Row(children: [
            Icon(Icons.bed),
            SizedBox(
              width: 10,
            ),
            Text("Retire"),
          ]),
        ),
        PopupMenuItem(
          enabled: eq.status == EquipageStatus.WAITING,
          value: "start-clearance",
          child: const Row(children: [
            Icon(Icons.check),
            SizedBox(
              width: 10,
            ),
            Text("Clear for start"),
          ]),
        ),
        PopupMenuItem(
          enabled: eq.status == EquipageStatus.WAITING,
          value: "change-category",
          child: const Row(children: [
            Icon(Icons.edit),
            SizedBox(
              width: 10,
            ),
            Text("Change category..."),
          ]),
        ),
        const PopupMenuItem(
          value: "show-info",
          child: Row(children: [
            Icon(Icons.info_outline),
            SizedBox(
              width: 10,
            ),
            Text("Show info..."),
          ]),
        ),
      ],
    );
