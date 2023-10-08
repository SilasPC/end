
import 'package:common/util.dart';
import 'package:esys_client/local_model/states.dart';
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
		// UI: add desync chip on icon
		var now = DateTime.now();
		if (conn.connected) _lastConn = now;
		// UI: not pretty
		return IconButton(
			color: conn.connected
				? (conn.state?.isSync ?? false ? Colors.green : Colors.amber)
				: Colors.red,
			icon: Icon(
				conn.connected
					? (conn.state?.isSync ?? false ? Icons.cloud_done : Icons.cloud)
					: Icons.cloud_off
			),
			onPressed: () {
				showDialog(
					context: context,
					builder: _syncMenu
				);
			},
		);
	}

	// UI: new sync indicator
	Widget _syncMenu(BuildContext context) {
		// var nearby = context.watch<NearbyManager>();
		var ppm = context.watch<LocalModel>();
		return Dialog(
			child: ListView(
				children: [
					ListTile(
						dense: true,
						title: Text("SessionId: ${ppm.manager.sessionId}")
					),
					ListTile(
						title: const Text("Server"),
						subtitle: Text(ppm.master?.state.name ?? "Disconnected"),
					),
					ListTile(
						title: Text("Android device"),
						subtitle: Text("13 event(s) old")
					)
				],
			)
		);
	}

	String _connDif() {
		var dif = DateTime.now().difference(_lastConn);
		return unixDifToMS(dif.inSeconds, false, false);
	}

}
