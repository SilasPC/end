
part of 'LocalModel.dart';

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

	ServerPeer? get peer => _pmm._master;
	PeerState? get state => peer?.state;
	bool get connected => peer?.connected ?? false;
	int? get sessionId => peer?.sessionId;
	bool get inSync => state?.isSync ?? false;

	late StreamSubscription _sub;

	final LocalModel _pmm;
	ServerConnection(this._pmm) {
		_sub = _pmm.serverUpdateStream.stream.listen((_) {
			notifyListeners();
		});
	}

	@override
	void dispose() {
		super.dispose();
		_sub.cancel();
	}

	int get desyncCount => peer?.desyncCount ?? 0;

	Future<bool> yieldRemote() async {
		var res = await peer?.send("yield", []);
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
	void dispose() {
		super.dispose();
		_sub.cancel();
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
	void dispose() {
		super.dispose();
		_sub.cancel();
	}

}
