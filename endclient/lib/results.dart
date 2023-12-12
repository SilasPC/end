
import 'package:common/models/Category.dart';
import 'package:common/util.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/services/local_model.dart';
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
               for (var MapEntry(key:eq, value:rank) in ranks.take(fin))
               EquipageTile(
                  eq,
                  leading: CircleAvatar(
                     backgroundColor: secondaryColor,
                     child: Text(
								rank.toString(),
								style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
							),
                  ),
						noStatus: true,
						trailing: [
							Column(
								mainAxisSize: MainAxisSize.min,
								crossAxisAlignment: CrossAxisAlignment.end,
								children: [
									if (eq.category.idealSpeed != null)
									Text(
										"${maybe(eq.idealTimeError(), unixHMS) ?? "-"} error",
										style: const TextStyle(
											fontWeight: FontWeight.bold,
										)
									)
									else
									Text(
										"${eq.averageSpeed()?.toStringAsFixed(1) ?? "-"} km/h",
										style: const TextStyle(
											fontWeight: FontWeight.bold,
										)
									),
									Text(
										"${maybe(eq.totalRideTime(), unixHMS) ?? "-"} ridetime",
									),
								],
							)
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
                     backgroundColor: secondaryColor,
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
