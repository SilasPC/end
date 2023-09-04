
import 'package:flutter/material.dart';

import '../LocalModel.dart';

class ConnectionIndicator extends StatelessWidget {
	
	const ConnectionIndicator({super.key});

	@override
	Widget build(BuildContext context) =>
		AnimatedBuilder(
			animation: LocalModel.instance.connection.status,
			builder: (context, _) =>
				LocalModel.instance.connection.status.value
					? Container()
					: IconButton(
						color: Colors.red,
						onPressed: (){},
						icon: const Icon(Icons.sync_problem),
					)
			);

}
