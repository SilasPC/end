
import 'package:common/p2p/Manager.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VariousStatesProvider extends StatelessWidget {

	const VariousStatesProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<LocalModel, ServerConnection>(
			create: (ctx) => ServerConnection(ctx.read<LocalModel>()),
			update: (_, __, val) => val!,
			child: ChangeNotifierProxyProvider<LocalModel, PeerStates>(
				create: (ctx) => PeerStates(ctx.read<LocalModel>().manager),
				update: (_, __, val) => val!,
				child: ChangeNotifierProxyProvider<LocalModel, SessionState>(
					create: (ctx) => SessionState(ctx.read<LocalModel>().manager),
					update: (_, __, val) => val!,
					child: child,
				)
			),
		);
	
}

class ServerConnection extends ChangeNotifier {

	PeerState? get state => pmm.master?.state;
	bool get connected => pmm.master?.connected ?? false;
	int? get sessionId => pmm.master?.sessionId;
	bool get inSync => state?.isSync ?? false;

	final LocalModel pmm;
	ServerConnection(this.pmm) {
		pmm.serverUpdateStream.stream.listen((_) {
			// PERF: dispose
			notifyListeners();
		});
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
			// PERF: dispose
			notifyListeners();
		});
	}

}

class SessionState extends ChangeNotifier {
	
	int get sessionId => manager.sessionId;

	final PeerManager manager;
	SessionState(this.manager) {
		manager.sessionStream.listen((_) {
			// PERF: dispose
			notifyListeners();
		});
	}
	
}
