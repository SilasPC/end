
import 'package:flutter/material.dart';

import '../LocalModel.dart';

class ConnectionIndicator extends StatelessWidget {
	
	const ConnectionIndicator({super.key});

	@override
	Widget build(BuildContext context) =>
		AnimatedBuilder(
			animation: LocalModel.instance.connection,
			builder: (context, _) =>
				LocalModel.instance.connection.value
					? Container()
					: IconButton(
						color: Colors.amber,
						onPressed: (){},
						icon: const Icon(Icons.sync_problem),
					)
			);

}