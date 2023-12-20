import 'package:esys_client/util/text_clock.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  TopBar({
    super.key,
  });

  final AppBar bar = AppBar(
    centerTitle: true,
    title: Container(
      height: 65,
      padding: const EdgeInsets.only(bottom: 6),
      child: FittedBox(
        child: TextClock(),
      ),
    ),
    actions: const [
      ConnectionIndicator2(
        iconOnly: true,
      )
    ],
  );

  @override
  Widget build(BuildContext context) => bar;

  @override
  Size get preferredSize => bar.preferredSize;
}
