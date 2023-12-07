

import 'package:esys_client/consts.dart';
import 'package:esys_client/v2/dashboard/component/connection_indicator.dart';
import 'package:esys_client/v2/dashboard/helpers.dart';
import 'package:flutter/material.dart';

import 'package:esys_client/util/text_clock.dart';

class DashboardMenu extends StatelessWidget {

	final List<NavItem> navItems;
	final int currentItem;
	final void Function(int) itemSelected;

	const DashboardMenu({
		super.key, required this.navItems, required this.itemSelected, required this.currentItem,
	});

	@override
	Widget build(BuildContext context) =>
		Container(
			width: 200,
			color: Theme.of(context).canvasColor,
			child: Column( // UI: listview
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
								for (var (i, navItem) in navItems.indexed)
								ListTile(
									leading: Icon(navItem.icon),
									title: Text(navItem.label),
									selected: currentItem == i,
									onTap: () => {
										if (i != currentItem) itemSelected(i)
									}
								),
							],
						),
					),
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
