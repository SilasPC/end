
import 'package:esys_client/consts.dart';
import 'package:esys_client/services/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectionIndicator2 extends StatelessWidget {

	final bool iconOnly;

	const ConnectionIndicator2({
		super.key,
		this.iconOnly = false,
	});

	@override
	Widget build(BuildContext context) {

		ServerConnection conn = context.watch();
		PeerStates peers = context.watch();
		var peerCount = peers.peers
			.where((p) => p.connected)
			.where((p) => p != conn.peer)
			.length;

		return switch (iconOnly) {
			// true when peerCount == 0 => _icon(conn),
			true =>
				IconButton(
					splashRadius: splashRadius,
					icon: Badge.count(
						isLabelVisible: peerCount > 0,
						count: peerCount,
						child: _icon(conn),
					),
					onPressed: () {},
				),
			false =>
				ListTile(
					leading: _icon(conn),
					title: Text(
						conn.connected ? "Connected" : "Disconnected",
						style: const TextStyle(
							color: Colors.grey
						)
					),
					subtitle: Text("$peerCount peer(s)"),
				),
		};

	}

	Widget _icon(ServerConnection conn) =>
		Icon(
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
		);

}
