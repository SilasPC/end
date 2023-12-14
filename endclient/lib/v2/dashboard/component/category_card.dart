
import 'package:common/models/glob.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/services/local_model.dart';
import 'package:esys_client/results.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryCard extends StatelessWidget {

	final Category cat;

	const CategoryCard({super.key, required this.cat});
	
	@override
	Widget build(BuildContext context) {
		int len = context.select((LocalModel _) => cat.equipages.length);
		int fin = context.select((LocalModel _) => cat.numFinished());
		int ended = context.select((LocalModel _) => cat.numEnded() - fin);
		int rem = len - fin - ended;
		return GestureDetector(
			onTap: () {
				Navigator.of(context)
					.push(MaterialPageRoute(
						builder: (context) => ResultsPage(cat: cat),
					));
			},
			child: Card(
				child: Column(
					children: [
						coloredCardheader(context, cat.name),
						Row(
							children: [
								Expanded(
									flex: fin,
									child: Divider(
										color: Colors.green,
										thickness: 8,
										height: 8,
									),
								),
								Expanded(
									flex: rem,
									child: Divider(
										color: Colors.black12,
										thickness: 8,
										height: 8,
									),
								),
								Expanded(
									flex: ended,
									child: Divider(
										color: Colors.red,
										thickness: 8,
										height: 8,
									),
								),
							],
						),
						const SizedBox(height: 4,),
						Flexible(
							fit: FlexFit.tight,
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.center,
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: [
									textCol("${cat.distance()} km", "distance"),
									textCol("${cat.loops.length}", "loops"),
								],
							),
						),
						Flexible(
							fit: FlexFit.tight,
							child: Builder(
								builder: (context) {
									return Row(
										crossAxisAlignment: CrossAxisAlignment.center,
										mainAxisAlignment: MainAxisAlignment.spaceEvenly,
										children: [
											textCol("$fin/$len", "finished"),
											textCol("$rem", "remaining"),
										],
									);
								}
							)
						),
						const SizedBox(height: 4,),
					]
				)
			)
		);
	}

	Widget textCol(String title, String subtitle) =>
		FittedBox(
			fit: BoxFit.contain,
			child: Column(
				mainAxisAlignment: MainAxisAlignment.center,
				children: [
					Text(title, style: const TextStyle(fontSize: 20)),
					Text(subtitle, style: const TextStyle()),
				],
			)
		);
}
