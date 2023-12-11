
import 'package:common/p2p/Manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../local_model/local_model.dart';

class ConnectionIndicator extends StatefulWidget {

	const ConnectionIndicator({super.key});

	@override
	State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {

	@override
	Widget build(BuildContext context) {
		var conn = context.watch<ServerConnection>();
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

	// IGNORED: UI: new sync indicator
	Widget _syncMenu(BuildContext context) {
		var conn = context.watch<ServerConnection>();
		var ses = context.select<SessionState, int>((s) => s.sessionId);
		var peers = context.watch<PeerStates>().peers;
		return Dialog(
			child: ListView(
				children: [
					ListTile(
						dense: true,
						title: Text("SessionId: $ses")
					),
					if (conn.peer case Peer p)
						_peerTile(p, "Server"),
					for (var p in peers)
						if (p != conn.peer)
							_peerTile(p)
				],
			)
		);
	}

	Widget _peerTile(Peer p, [String? name]) =>
		ListTile(
			title: Text(name ?? p.id ?? "-"),
			// tileColor: p.connected ? Colors.green : Colors.red,
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
						context.read<LocalModel>().manager.yieldTo(p);
					},
				) : null,
		);

}
