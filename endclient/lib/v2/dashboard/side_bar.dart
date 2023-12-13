

import 'package:esys_client/consts.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:flutter/material.dart';

import 'package:esys_client/util/text_clock.dart';

class SideBar extends StatelessWidget {

	final List<NavItem> navItems;
	final NavItem currentItem;
	final void Function(NavItem) itemSelected;
	final bool noClock;

	const SideBar({
		super.key,
		required this.navItems,
		required this.itemSelected,
		required this.currentItem,
		this.noClock = false,
	});

	@override
	Widget build(BuildContext context) =>
		Container(
			width: 200,
			color: Theme.of(context).canvasColor,
			child: Column(
				children: [
					SizedBox(
						height: 60,
						child: Center(
							child: Text(
								"eSys",
								style: TextStyle(
									fontSize: 20,
									color: Theme.of(context).colorScheme.onSurface
								),
							)
						),
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
										if (navItem != currentItem) itemSelected(navItem)
									}
								),
							],
						),
					),
					if (!noClock)
					SizedBox(
						width: 150,
						child: FittedBox(
							fit: BoxFit.fitWidth,
							child: TextClock()
						),
					),
					const Divider(),
					ListTile(
						/* leading: CircleAvatar(
							child: Icon(Icons.person),
						), */
						title: const Text("Username"),
						subtitle: const Text("Something"),
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
			)
		);

}
