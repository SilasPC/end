
import 'dart:io';

import 'package:common/models/glob.dart';
import 'package:esys_client/settings_provider.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
import 'package:locally/locally.dart';
import 'package:provider/provider.dart';
import '../LocalModel.dart';
import 'category.dart';
import 'eventview.dart';
import 'modelview.dart';
import 'util.dart';

class SecretaryPage extends StatefulWidget {
	const SecretaryPage({super.key});

	@override
	State createState() => SecretaryPageState();
}

class SecretaryPageState extends State<SecretaryPage> {

	List<Category> _finishedCats = [];

	Widget textCol(String title, String subtitle) =>
		Column(
			children: [
				Text(title, style: const TextStyle(fontSize: 20)),
				Text(subtitle, style: const TextStyle()),
			],
		);

	Widget catCard(Category cat) {
		int fin = cat.numFinished();
		int dnf = cat.numDNF();
		int rem = cat.equipages.length - fin - dnf;

		return AspectRatio(
			aspectRatio: 1,
			child: Card(
				child: Column(
					children: [
						cardHeader(context, cat.name, color: const Color.fromARGB(255, 146, 119, 68)),
						
						Container(
							padding: const EdgeInsets.all(10),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: [
									textCol("$fin/${cat.equipages.length}", "finished"),
									textCol("$rem", "remaining"),
								],
							)
						),
					],
				),
			)
		);
	}

	Widget headerCard(String rideName) =>
		Card(
			color: const Color.fromARGB(255, 98, 85, 115),
			child: Column(
				children: [
					cardHeader(context, rideName),
					/*Row(
						mainAxisAlignment: MainAxisAlignment.end,
						children: [
							IconButton(
								onPressed: (){},
								icon: const Icon(Icons.timer)
							),
						],
					),*/
				],
			),
		);

	List<Widget> viewTabs(Map<String,Category> cats, bool showAdmin) => [
		const Tab(icon: Icon(Icons.apps), text: "Overview"),
		for (Category cat in cats.values)
			Tab(icon: const Icon(Icons.group), text: "${cat.name} ${cat.distance()}km"),
		if (showAdmin)
			const Tab(icon: Icon(Icons.list), text: "Events"),
		if (showAdmin)
			const Tab(icon: Icon(Icons.account_tree), text: "Model"),
	];
	Widget tabView(Model model, bool showAdmin) => TabBarView(
		children: [
			Container(
				padding: const EdgeInsets.all(10),
				child: Column(
					children: [
						headerCard(model.rideName),
						Expanded(
							child: GridView.count(
								// clipBehavior: Clip.none,
								crossAxisCount: 2,
								children: model.categories.values.map(catCard).toList(),
							),
						)
					],
				)
			),
			for (Category cat in model.categories.values)
				CategoryView(cat),
			if (showAdmin)
				const EventView(),
			if (showAdmin)
				const ModelView(),
		],
	);

	bool isInit = false;

	@override
	Widget build(BuildContext context) =>
		Consumer<LocalModel>(
			builder: (context, model, child) {
				
				var showAdmin = context.watch<Settings>().showAdmin;
				
				var newFin = model.model.categories
					.values
					.where((cat) => cat.isEnded() && !_finishedCats.contains(cat))
					.toList();

				_finishedCats.addAll(newFin);
				if (isInit && (Platform.isAndroid || Platform.isIOS)) {
					for (var cat in newFin) {
						Locally(
							context: context,
							pageRoute: MaterialPageRoute(builder: (_) => widget),
							payload: "wutisdis",
							appIcon: "mipmap/ic_launcher",
						).show(title: "Category finished", message: cat.name);
					}
				}
				isInit = true;

				return DefaultTabController(
					length: 1 + model.model.categories.length + (showAdmin ? 2 : 0),
					child: Scaffold(
							appBar: AppBar(
								actions: const [ConnectionIndicator()],
								title: const Text("Secretary"),
								bottom: TabBar(
									isScrollable: true,
									tabs: viewTabs(model.model.categories, showAdmin),
								),
							),
							body: Stack(
								children: [
									Container(
										decoration: const BoxDecoration(
											image: DecorationImage(
												image: AssetImage("assets/horse.jpg"),
												fit: BoxFit.cover
											),
										),
									),
									tabView(model.model, showAdmin),
								],
							)
					)
				);
			}
		);
}
