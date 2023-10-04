
import 'package:common/EventModel.dart';
import 'package:common/event_model/OrderedSet.dart';
import 'package:common/models/glob.dart';
import 'package:esys_client/local_model/PeerManagedModel.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ModelProvider extends StatelessWidget {
	const ModelProvider({super.key, required this.child});

	final Widget child;

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProxyProvider<Settings, LocalModel>(
			lazy: false,
			create: (_) => PeerManagedModel(),
			update: (_, set, mod) {
				mod!.setServerUri(set.serverURI);
				return mod;
			},
			child: child,
		);
}

abstract class LocalModel with ChangeNotifier {

	Model get model;
	Set<Event<Model>> get deletes;
	ReadOnlyOrderedSet<Event<Model>> get events;

	int get desyncCount;

	void setServerUri(String uri);

	Future<void> addSync(List<Event<Model>> evs, [List<Event<Model>> dels = const []]);
	Future<void> resetSync();

}
