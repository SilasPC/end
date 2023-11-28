// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:common/models/glob.dart';
import 'package:esys_client/consts.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:esys_client/v2/dashboard/util/util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryCard extends StatelessWidget {

	final Category cat;

	const CategoryCard({super.key, required this.cat});
	
	@override
	Widget build(BuildContext context) {
		const borderRadius = 20.0; // TODO: provider

		return Card(
			child: Column(
				children: [
					coloredCardheader(cat.name),
					SizedBox(height: 4,),
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
								int len = context.select((LocalModel _) => cat.equipages.length);
								int fin = context.select((LocalModel _) => cat.numFinished());
								int dnf = context.select((LocalModel _) => cat.numDNF());
								int rem = len - fin - dnf;
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
					SizedBox(height: 4,),
				]
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
