import 'package:esys_client/services/identity.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/v2/dashboard/component/event_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EventSidebar extends StatelessWidget {
  const EventSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    LocalModel model = context.watch();
    var author = context.watch<IdentityService>().author;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Center(
                child: Text(
              "eSys",
              style: TextStyle(
                  fontSize: 20, color: Theme.of(context).colorScheme.onSurface),
            )),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                for (var (ordIdx, ev) in model.events.iterator.indexed)
                  if (ev.author == author)
                    EventTile(insertionIndex: model.events.toInsIndex(ordIdx)!)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
