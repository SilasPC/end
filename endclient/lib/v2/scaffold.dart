import 'package:esys_client/v2/app_bars/event_side_bar.dart';
import 'package:esys_client/v2/app_bars/nav_side_bar.dart';
import 'package:esys_client/v2/app_bars/top_bar.dart';
import 'package:flutter/material.dart';

class MyScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;

  const MyScaffold(
      {super.key,
      required this.body,
      this.bottomNavigationBar,
      this.floatingActionButton,
      this.floatingActionButtonLocation,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: TopBar(),
        drawer: NavSidebar.fromContext(context),
        drawerEnableOpenDragGesture: false,
        endDrawerEnableOpenDragGesture: false,
        endDrawer: EventSidebar(),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: body);
  }
}
