import 'package:esys_client/consts.dart';
import 'package:esys_client/services/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectionIndicator2 extends StatelessWidget {
  final bool iconOnly;
  final void Function()? onTap;

  const ConnectionIndicator2({super.key, this.iconOnly = false, this.onTap});

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
      true => IconButton(
          splashRadius: splashRadius,
          icon: Badge.count(
            isLabelVisible: peerCount > 0,
            count: peerCount,
            child: _icon(conn),
          ),
          onPressed: () => onTap?.call(),
        ),
      false => ListTile(
          onTap: onTap,
          leading: _icon(conn),
          title: Text(conn.connected ? "Connected" : "Disconnected"),
          subtitle: Text("$peerCount peer(s)"),
        ),
    };
  }

  Widget _icon(ServerConnection conn) => Icon(
      switch ((conn.connected, conn.state?.isSync)) {
        (false, _) => Icons.cloud_off,
        (true, true) => Icons.cloud_done,
        _ => Icons.cloud,
      },
      color: switch ((conn.connected, conn.state?.isSync)) {
        (false, _) => Colors.red,
        (true, true) => Colors.green,
        _ => Colors.amber,
      });
}
