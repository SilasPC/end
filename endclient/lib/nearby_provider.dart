
import 'package:esys_client/p2p/nearby.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
	}

	@override
	void dispose() {
		_nearbyMan.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) =>
		ChangeNotifierProvider.value(
			value: _nearbyMan,
			child: widget.child,
		);

}
