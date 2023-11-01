
import 'package:common/util.dart';
import 'package:esys_client/local_model/states.dart';
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
		var now = DateTime.now();
		if (conn.connected) _lastConn = now;
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
		var ppm = context.watch<LocalModel>();
		var ses = context.select<SessionState, int>((s) => s.sessionId);
		var peers = context.watch<PeerStates>().peers;
		return Dialog(
			child: ListView(
				children: [
					ListTile(
						dense: true,
						title: Text("SessionId: $ses")
					),
					ListTile(
					title: const Text("Server"),
						tileColor: ppm.master?.connected ?? false ? Colors.green : Colors.red,
						subtitle: Text(ppm.master?.connected ?? false ? ppm.master!.state.name : "Disconnected"),
						onLongPress: () {
							if (ppm.master == null) return;
							if (ppm.master!.connected) {
								ppm.master!.disconnect();
							} else {
								ppm.master!.connect();
							}
						},
						trailing: ppm.master?.state.isConflict ?? false
							? IconButton(
								icon: const Icon(Icons.cloud_download),
								onPressed: () {
									ppm.manager.yieldTo(ppm.master!);
								},
							) : null,
					),
					for (var p in peers)
					if (p != ppm.master)
					ListTile(
						title: Text(p.id ?? "-"),
						tileColor: p.connected ? Colors.green : Colors.red,
						subtitle: Text(p.connected ? p.state.name : "Disconnected"),
						onLongPress: () {
							if (p.connected) {
								p.disconnect();
							} else {
								p.connect();
							}
						},
						trailing: p.state.isConflict
							? IconButton(
								icon: const Icon(Icons.cloud_download),
								onPressed: () {
									ppm.manager.yieldTo(p);
								},
							) : null,
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
