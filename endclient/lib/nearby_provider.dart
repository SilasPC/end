
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/p2p/nearby.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';

class NearbyProvider extends StatefulWidget {

	final Widget child;

	const NearbyProvider({super.key, required this.child});

	@override
	State<NearbyProvider> createState() => _NearbyProviderState();
}

class _NearbyProviderState extends State<NearbyProvider> {

	late NearbyManager _nearbyMan;
	
	@override
	void initState() {
		super.initState();
		_nearbyMan = NearbyManager();
		_nearbyMan.addListener(() {
         var lm = context.read<LocalModel>();
         for (var p in _nearbyMan.devices) {
            lm.manager.addPeer(p);
         }
		});
	}

	@override
	void dispose() {
		_nearbyMan.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		var useP2p = context.select<Settings, bool>((s) => s.useP2P);
		var inSync = context.select<ServerConnection, bool>((c) => c.inSync);
		_nearbyMan.enabled = useP2p;
		_nearbyMan.autoConnect = !inSync;

		return ChangeNotifierProvider.value(
			value: _nearbyMan,
			child: widget.child,
		);
	}

}
