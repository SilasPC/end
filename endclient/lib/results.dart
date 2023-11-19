
import 'package:common/models/Category.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/equipage/equipage_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResultsPage extends StatelessWidget {

   final Category cat;

   const ResultsPage({super.key, required this.cat});

   @override
   Widget build(BuildContext context) {
      context.watch<LocalModel>();
      var ranks = cat.rankings();
		var fin = ranks.takeWhile((e) => e.key.isFinished).length;
      return Scaffold(
			// backgroundColor: Colors.transparent,
         appBar: AppBar(
            title: Text("Results ${cat.name}"),
         ),
         body: ListView(
            children: [
					ListTile(
						dense: true,
						title: Text("Finished ($fin/${ranks.length})"),
					),
               for (var entry in ranks.take(fin))
               EquipageTile(
                  entry.key,
                  leading: CircleAvatar(
                     backgroundColor: const Color.fromARGB(255, 146, 119, 68),
                     child: Text(
								entry.value.toString(),
								style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
							),
                  ),
						noStatus: true,
						trailing: [
							// UI: better container
							CircleAvatar(
								backgroundColor: const Color.fromARGB(255, 98, 85, 115),
								child: Text(
									"${entry.key.averageSpeed()?.toStringAsFixed(1) ?? "-"} km/h",
									style: const TextStyle(color: Colors.white),
								),
							),
						],
               ),
					if (ranks.length > fin)
					ListTile(
						dense: true,
						title: Text("Unfinished (${ranks.length - fin}/${ranks.length})"),
					),
					for (var entry in ranks.skip(fin))
					EquipageTile(
                  entry.key,
                  leading: CircleAvatar(
                     backgroundColor: const Color.fromARGB(255, 146, 119, 68),
                     child: Text(
								entry.value.toString(),
								style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
							),
                  )
               )
            ],
         ),
      );
   }

}
