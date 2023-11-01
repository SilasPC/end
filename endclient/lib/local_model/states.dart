
import 'dart:async';

import 'package:common/p2p/Manager.dart';
import 'package:esys_client/local_model/LocalModel.dart';
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

	late StreamSubscription _sub;

	final LocalModel pmm;
	ServerConnection(this.pmm) {
		_sub = pmm.serverUpdateStream.stream.listen((_) {
			notifyListeners();
		});
	}

	@override
	void dipose() {
		_sub.cancel();
		super.dispose();
	}

	int get desyncCount => pmm.desyncCount;

	Future<bool> yieldRemote() async {
		var res = await pmm.master?.send("yield", []);
		return res?.firstOrNull == 1;
	}

}

class PeerStates extends ChangeNotifier {

	List<Peer> get peers => manager.peers;

	late StreamSubscription _sub;

	final PeerManager manager;
	PeerStates(this.manager) {
		_sub = manager.peerStateChanges.listen((_) {
			notifyListeners();
		});
	}

	@override
	void dipose() {
		_sub.cancel();
		super.dispose();
	}

}

class SessionState extends ChangeNotifier {

	int get sessionId => manager.sessionId;

	late StreamSubscription _sub;

	final PeerManager manager;
	SessionState(this.manager) {
		_sub = manager.sessionStream.listen((_) {
			notifyListeners();
		});
	}

	void reset() => manager.resetSession();

	@override
	void dipose() {
		_sub.cancel();
		super.dispose();
	}

}
