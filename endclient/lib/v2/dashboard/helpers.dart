import 'package:flutter/widgets.dart';

class NavItem {
  final Widget view;
  final String label;
  final IconData icon;

  const NavItem({required this.view, required this.label, required this.icon});
}

class UI {
  final bool narrow;
  final List<NavItem> navItems;
  final NavItem currentNavItem;
  final void Function(NavItem) navigate;
  const UI(this.narrow, this.navItems, this.currentNavItem, this.navigate);
}
