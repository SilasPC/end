
import 'package:common/util.dart';
import 'package:esys_client/local_model/ServerConnection.dart';
import 'package:esys_client/p2p/nearby.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../local_model/LocalModel.dart';

class ConnectionIndicator extends StatefulWidget {
	
	const ConnectionIndicator({super.key});

	@override
	State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {

	static DateTime _lastConn = DateTime.now();

	@override
	Widget build(BuildContext context) {
		var conn = context.watch<ServerConnection>();
		// var nearby = context.watch<NearbyManager>();
		// UI: add desync chip on icon
		var now = DateTime.now();
		if (conn.connected) _lastConn = now;
		return PopupMenuButton(
			child: Icon(
				conn.connected
					? Icons.cloud_done
					: Icons.cloud_off
			),
			itemBuilder: (context) => [
				PopupMenuItem(
					child: ListTile(
						title: Text("Server"),
						subtitle: Text("In sync"),
					),
				),
				PopupMenuItem(
					child: ListTile(
						title: Text("Server"),
						subtitle: Text("In sync"),
						trailing: Switch(
							value: true,
							onChanged: null,
						),
					),
				),
			]
		);
		/* return IconButton(
				color: conn.connected ? Colors.green : Colors.red,
				onPressed: () {
					var dif = now.difference(_lastConn);
					var difStr = unixDifToMS(dif.inSeconds, false, false);
					ScaffoldMessenger.of(context)
						.showSnackBar(SnackBar(
							action: SnackBarAction(
								label: "Settings...",
								onPressed: () {
									Navigator.of(context)
										.push(MaterialPageRoute(
											builder: (BuildContext context) => const BluetoothPage()
										));
								},
							),
							content: Text(
								"Server connection unavailable ($difStr).\n"
								"${conn.desyncCount} unsynced event(s)."
							),
						));
				},
				icon: 
			); */
	}

	// UI: new sync indicator
	Widget _syncMenu() {
		return ListView(
			children: [
				ListTile(
					title: Text("Server"),
					subtitle: Text("Syncronized"),
				),
				Divider(),
				ListTile(
					title: Text("P2P enabled"),
					trailing: Switch(
						value: false,
						onChanged: null,
					),
				),
				Divider(),
				ListTile(
					title: Text("Android device"),
					subtitle: Text("13 event(s) old")
				)
			],
		);
	}

}
