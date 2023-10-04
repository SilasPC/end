
import 'package:common/util.dart';
import 'package:esys_client/bluetooth.dart';
import 'package:esys_client/local_model/ServerConnection.dart';
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
		// UI: add desync chip on icon
		var now = DateTime.now();
		if (conn.connected) _lastConn = now;
		return conn.connected
			? Container()
			: IconButton(
				color: Colors.red,
				// TODO: open sync settings?
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
				icon: const Icon(Icons.sync_problem),
			);
	}
}
