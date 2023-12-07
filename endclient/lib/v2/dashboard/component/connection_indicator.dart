// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:esys_client/local_model/LocalModel.dart';
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
				Badge.count(
					child: _icon(conn),
					count: peerCount
				),
			false =>
				ListTile(
					leading: _icon(conn),
					title: Text(
						conn.connected ? "Connected" : "Disconnected",
						style: TextStyle(
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
