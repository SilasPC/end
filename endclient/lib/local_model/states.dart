
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
				child: StreamedProxyProvider<LocalModel, SessionState, int>(
					create: (lm) => SessionState(lm.manager),
					stream: (lm) => lm.manager.sessionStream,
					child: child,
				)
			),
		);
	
}

class ServerConnection /* extends ChangeNotifier */ {

	PeerState? get state => pmm.master?.state;
	bool get connected => pmm.master?.connected ?? false;
	int? get sessionId => pmm.master?.sessionId;
	bool get inSync => state == PeerState.SYNC;

	final LocalModel pmm;
	ServerConnection(this.pmm) {
		/* pmm.serverUpdateStream.stream.listen((_) {
			notifyListeners();
		}); */
	}

	int get desyncCount => pmm.desyncCount;

	Future<bool> yieldRemote() async {
		var res = await pmm.master?.send("yield", []);
		return res?.firstOrNull == 1;
	}

}

class PeerStates extends ChangeNotifier {

	List<Peer> get peers => manager.peers;

	final PeerManager manager;
	PeerStates(this.manager) {
		manager.peerStateChanges.listen((_) {
			notifyListeners();
		});
	}

}

class SessionState extends ChangeNotifier {
	
	int get sessionId => manager.sessionId;

	final PeerManager manager;
	SessionState(this.manager) {
		manager.sessionStream.listen((_) {
			notifyListeners();
		});
	}
	
}
