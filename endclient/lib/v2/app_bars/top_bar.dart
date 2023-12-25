import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) => AppBar(
        centerTitle: true,
        title: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.only(bottom: 6),
          child: FittedBox(
            child: TextClock(),
          ),
        ),
        actions: [
          ConnectionIndicator2(
            iconOnly: true,
            onTap: () {
              Scaffold.of(context).openEndDrawer();
            },
          )
        ],
      );

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
