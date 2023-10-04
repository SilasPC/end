
import 'package:common/util.dart';
import 'package:esys_client/bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../LocalModel.dart';

class ConnectionIndicator extends StatefulWidget {
	
	const ConnectionIndicator({super.key});

	@override
	State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {

	static DateTime _lastConn = DateTime.now();

	@override
	Widget build(BuildContext context) {
		var model = context.read<LocalModel>();
		var desync = context.select<LocalModel, int>((lm) => lm.desyncCount);
		// UI: add desync chip on icon
		return AnimatedBuilder(
			animation: model.connection,
			builder: (context, _) {
				bool status = model.connection.value;
				var now = DateTime.now();
				if (status) _lastConn = now;
				return status
					? Container()
					: IconButton(
						color: Colors.red,
						// TODO: open sync settings?
						onPressed: () {
							var dif = now.difference(_lastConn);
							var difStr = unixDifToMS(dif.inSeconds, false, false);
							ScaffoldMessenger.of(context)
								.showSnackBar(SnackBar(
									action: SnackBarAction(
										label: "Settings...",
										onPressed: () {
											Navigator.of(context)
												.push(MaterialPageRoute(
													builder: (BuildContext context) => const BluetoothPage()
												));
										},
									),
									content: Text(
										"Server connection unavailable ($difStr).\n"
										"$desync unsynced event(s)."
									),
								));
						},
						icon: const Icon(Icons.sync_problem),
					);
			}
		);
	}
}
