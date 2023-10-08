
import 'package:common/p2p/Manager.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/util/util.dart';
import 'package:flutter/material.dart';

class VariousStatesProvider extends StatelessWidget {

	const VariousStatesProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		StreamedProxyProvider<LocalModel, ServerConnection, void>(
			create: (lm) => ServerConnection(lm),
			stream: (lm) => lm.serverUpdateStream.stream,
			child: StreamedProxyProvider<LocalModel, PeerStates, Peer>(
				create: (lm) => PeerStates(lm.manager),
				stream: (lm) => lm.manager.peerStateChanges,
				child: child
			),
		);
	
}

class ServerConnection {

	PeerState? get state => pmm.master?.state;
	bool get connected => pmm.master?.connected ?? false;
	int? get sessionId => pmm.master?.sessionId;

	final LocalModel pmm;
	ServerConnection(this.pmm);

	int get desyncCount => pmm.desyncCount;

	Future<bool> yieldRemote() async {
		var res = await pmm.master?.send("yield", []);
		return res?.firstOrNull == 1;
	}

}

class PeerStates {

	List<Peer> get peers => manager.peers;

	final PeerManager manager;
	PeerStates(this.manager);

}
