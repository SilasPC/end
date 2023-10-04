
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/local_model/PeerManagedModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServerConnectionProvider extends StatelessWidget {
	const ServerConnectionProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<LocalModel, ServerConnection>(
			create: (_) => ServerConnection(null),
			update: (_, model, last) {
				if (last?.pmm == model) {
					return last!;
				}
				if (model is PeerManagedModel) {
					return ServerConnection(model);
				}
				return ServerConnection(null);
			},
			child: child,
		);
}

class ServerConnection with ChangeNotifier {

	bool get connected => pmm?.master?.connected ?? false;

	final PeerManagedModel? pmm;
	ServerConnection(this.pmm);

	int get desyncCount => pmm?.desyncCount ?? 0;

	Future<bool> yieldRemote() async {
		var res = await pmm?.master?.send("yield", []);
		return res?.firstOrNull == 1;
	}

}
