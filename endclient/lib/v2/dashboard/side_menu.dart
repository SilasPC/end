
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/overview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_view.dart';
import 'gate.dart';
import 'settings_view.dart';

import 'package:esys_client/util/text_clock.dart';

class DashboardMenu extends StatefulWidget {

	static Widget defaultView() => OverviewView();

	final void Function(Widget) viewSelected;

	const DashboardMenu({super.key, required this.viewSelected});

	@override
	State<DashboardMenu> createState() => _DashboardMenuState();

}

class _DashboardMenuState extends State<DashboardMenu> {

	Type current = OverviewView;

	void setCurrent<T extends Widget>(T Function() f) {
		if (current != T) {
			setState(() {
				current = T;
			});
			widget.viewSelected(f());
		}
	} 

	@override
	Widget build(BuildContext context) =>
		Column( // UI: listview
			children: [
				SizedBox(
					height: 60,
					child: Center(
						child: Text(
							"eSys",
							style: TextStyle(fontSize: 20, color: Colors.white38),
						)
					),
				),
				Divider(),
				SizedBox(height: 25,),
				ListTile(
					leading: Icon(Icons.grid_view),
					title: Text("Overview"),
					tileColor: current == OverviewView ? Colors.black26 : null,
					onTap: () => setCurrent(OverviewView.new)
				),
				ListTile(
					leading: Icon(Icons.data_array),
					title: Text("Data"),
					tileColor: current == DataView ? Colors.black26 : null,
					onTap: () => setCurrent(DataView.new)
				),
				ListTile(
					leading: Icon(Icons.flag),
					title: Text("Gates"),
					tileColor: current == GateView ? Colors.black26 : null,
					onTap: () => setCurrent(GateView.new)
				),
				/* ListTile(
					leading: Icon(MyIcons.equipe),
					title: Text("Equipe"),
					onTap: () {},
				), */
				ListTile(
					leading: Icon(Icons.settings),
					title: Text("Settings"),
					tileColor: current == SettingsView ? Colors.black26 : null,
					onTap: () => setCurrent(SettingsView.new)
				),
				/* ListTile(
					leading: Icon(Icons.admin_panel_settings),
					title: Text("Administration"),
					onTap: () {},
				), */
				Spacer(),
				SizedBox(
					width: 150,
					child: FittedBox(
						fit: BoxFit.fitWidth,
						child: TextClock()
					),
				),
				Divider(),
				ListTile(
					/* leading: CircleAvatar(
						child: Icon(Icons.person),
					), */
					title: Text("Username"),
					subtitle: Text("Something"),
					trailing: IconButton(
						splashRadius: 20, // TODO: provider
						icon: Icon(Icons.logout),
						onPressed: () {
							Navigator.of(context).pop();
						},
					),
				),
				Divider(),
				Builder(
					builder: (context) {

						ServerConnection conn = context.watch();
						PeerStates peers = context.watch();
						var peerCount = peers.peers
							.where((p) => p.connected)
							.where((p) => p != conn.peer)
							.length;

						return ListTile(
							leading: Icon(
								switch ((conn.connected, conn.state?.isSync)) {
									(false, _) => Icons.cloud_off,
									(true, true) => Icons.cloud_done,
									_ => Icons.cloud,
								},
								color: switch ((conn.connected, conn.state?.isSync)) {
									(false, _) => Colors.red,
									(true, true) => Colors.green,
									_ => Colors.amber,
								}
							),
							title: Text(
								conn.connected ? "Connected" : "Disconnected",
								style: TextStyle(
									color: Colors.grey
								)
							),
							subtitle: Text("$peerCount peer(s)"),
						);
					},
				)
			],
		);

}
