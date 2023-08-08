
import 'package:common/Equipe.dart';
import 'package:flutter/material.dart';

import 'LocalModel.dart';
import 'util/input_modals.dart';

class SettingsPage extends StatelessWidget {

   const SettingsPage({super.key});

   @override
   Widget build(BuildContext context) =>
      Scaffold(
         appBar: AppBar(
            title: const Text("Settings"),
         ),
         body: ListView(
            children: [
               ListTile(
                  title: TextField(
							decoration: const InputDecoration(
								label: Text("Server address"),
							),
                     controller: TextEditingController(text: "kastanie.ddns.net:3000"),
                  )
               ),
					ListTile(
						leading: const Icon(Icons.sync),
                  title: const Text("Resync"),
						onTap: () => LocalModel.instance.resetAndSync(),
               ),
					const ListTile(
						title: Text("Administration"),
						dense: true,
					),
					ListTile(
                  title: const Text("Reset remote model"),
						onTap: () {}
               ),
					ListTile(
						title: const Text("Load remote model..."),
						onTap: () => loadModel(context),
					),



            ],
         ),
      );

		Future<void> loadModel(BuildContext context) async {
			var meets = await loadRecentMeetings();
			showChoicesModal(
				context,
				["DEMO"]..addAll(meets.map((e) => e.name)),
				(name) async {
					if (name == "DEMO") {
						return;
					}
					int id = meets.firstWhere((e) => e.name == name).id;
					return;
				}
			);
		}

}
