
import 'package:common/models/glob.dart';
import 'package:esys_client/util/connection_indicator.dart';
import 'package:flutter/material.dart';
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
						cardHeader("${cat.name} ${cat.distance()}km"),
						const Divider(),
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
			//color: const Color.fromARGB(255, 228, 190, 53),
			child: Column(
				children: [
					cardHeader(rideName),
					const Divider(),
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

	List<Widget> viewTabs(Map<String,Category> cats) => [
		const Tab(icon: Icon(Icons.apps), text: "Overview"),
		for (Category cat in cats.values)
			Tab(icon: const Icon(Icons.group), text: "${cat.name} ${cat.distance()}km"),
		const Tab(icon: Icon(Icons.list), text: "Events"),
		const Tab(icon: Icon(Icons.account_tree), text: "Model"),
	];
	Widget tabView(Model model) => TabBarView(
		children: [
			Container(
				padding: const EdgeInsets.all(10), // todo fix
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
			const EventView(),
			const ModelView(),
		],
	);

	@override
	Widget build(BuildContext context) =>
		Consumer<LocalModel>(
			builder: (context, model, child) {
				return DefaultTabController(
					length: 3 + model.model.categories.length,
					child: Scaffold(
							appBar: AppBar(
								actions: const [ConnectionIndicator()],
								title: const Text("Secretary"),
								bottom: TabBar(
									isScrollable: true,
									tabs: viewTabs(model.model.categories),
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
									tabView(model.model),
								],
							)
					)
				);
			}
		);
}
