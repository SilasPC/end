
import 'package:common/util.dart';
import 'package:flutter/material.dart';

import '../LocalModel.dart';

class ConnectionIndicator extends StatefulWidget {
	
	const ConnectionIndicator({super.key});

	@override
	State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {

	DateTime lastConn = DateTime.now();

	@override
	Widget build(BuildContext context) =>
		AnimatedBuilder(
			animation: LocalModel.instance.connection.status,
			builder: (context, _) =>
				LocalModel.instance.connection.status.value
					? Container()
					: IconButton(
						color: Colors.red,
						onPressed: () {
							var dif = DateTime.now().difference(lastConn);
							var difStr = unixDifToMS(dif.inSeconds);
							ScaffoldMessenger.of(context)
								.showSnackBar(SnackBar(
									content: Text("Server connection unavailable ($difStr)"),
								));
						},
						icon: const Icon(Icons.sync_problem),
					)
			);
}
