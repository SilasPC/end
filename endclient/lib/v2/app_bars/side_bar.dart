import 'package:esys_client/consts.dart';
import 'package:esys_client/services/identity.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:flutter/material.dart';

import 'package:esys_client/util/text_clock.dart';
import 'package:provider/provider.dart';

class SideBar extends StatelessWidget {
  final List<NavItem> navItems;
  final NavItem currentItem;
  final void Function(NavItem)? itemSelected;
  final bool noClock;

  const SideBar({
    super.key,
    required this.navItems,
    required this.itemSelected,
    required this.currentItem,
    this.noClock = false,
  });

  static SideBar? fromUI(UI ui) {
    if (!ui.narrow) return null;
    return SideBar(
      currentItem: ui.currentNavItem,
      navItems: ui.navItems,
      itemSelected: ui.navigate,
      noClock: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    var canvasColor = Theme.of(context).canvasColor;
    var canvasAccent = Color.alphaBlend(Colors.white24, canvasColor);
    var author = context.watch<IdentityService>().author;
    return Container(
        width: 200,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            0.1,
            0.5,
            0.9,
          ],
          colors: [
            canvasColor,
            canvasAccent,
            canvasColor,
          ],
        )),
        // color: Theme.of(context).canvasColor,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Center(
                  child: Text(
                "eSys",
                style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface),
              )),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (var navItem in navItems)
                    ListTile(
                        leading: Icon(navItem.icon),
                        title: Text(navItem.label),
                        selected: currentItem == navItem,
                        onTap: () => {
                              if (navItem != currentItem)
                                itemSelected?.call(navItem)
                            }),
                ],
              ),
            ),
            if (!noClock)
              SizedBox(
                width: 150,
                child: FittedBox(fit: BoxFit.fitWidth, child: TextClock()),
              ),
            const Divider(),
            ListTile(
              /* leading: CircleAvatar(
							child: Icon(Icons.person),
						), */
              title: Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // subtitle: const Text("Something"),
              trailing: IconButton(
                splashRadius: splashRadius,
                icon: const Icon(Icons.logout),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Divider(),
            const ConnectionIndicator2()
          ],
        ));
  }
}
