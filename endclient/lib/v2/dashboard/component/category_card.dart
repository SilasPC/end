// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:common/models/glob.dart';
import 'package:esys_client/local_model/LocalModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryCard extends StatelessWidget {

	final Category cat;

	const CategoryCard({super.key, required this.cat});
	
	@override
	Widget build(BuildContext context) {
		int len = context.select((LocalModel _) => cat.equipages.length);
		int fin = context.select((LocalModel _) => cat.numFinished());
		int dnf = context.select((LocalModel _) => cat.numDNF());
		int rem = len - fin - dnf;
		const borderRadius = 20.0; // TODO: provider

		// UI: align, overflow, etc.
		return Card(
			child: Column(
				children: [
					Container(
						height: 50,
						padding: const EdgeInsets.symmetric(horizontal: 8),
						alignment: Alignment.center,
						decoration: BoxDecoration(
							borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
							color: Colors.black54,
						),
						child: Text(
							cat.name,
							overflow: TextOverflow.ellipsis,
							maxLines: 1,
							style: TextStyle(
								fontSize: 20,
							)
						)
					),
					Container(
						padding: const EdgeInsets.all(10),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								textCol("${cat.distance()} km", "distance"),
								textCol("${cat.loops.length}", "loops"),
							],
						)
					),
					Divider(),
					Container(
						padding: const EdgeInsets.all(10),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: [
								textCol("$fin/$len", "finished"),
								textCol("$rem", "remaining"),
							],
						)
					),
				]
			)
		);
	}

	Widget textCol(String title, String subtitle) =>
		Column(
			children: [
				Text(title, style: const TextStyle(fontSize: 20)),
				Text(subtitle, style: const TextStyle()),
			],
		);
}
