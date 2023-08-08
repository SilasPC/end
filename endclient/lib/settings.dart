
import 'package:flutter/material.dart';

import 'LocalModel.dart';

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
                  title: const Text("Reset local model"),
						onTap: () => LocalModel.instance.resetAndSync(),
               ),
					ListTile(
                  title: const Text("Reset remote model"),
						onTap: () {}
               ),
               ListTile(
                  title: TextField(
							decoration: const InputDecoration(
								label: Text("Server address"),
							),
                     controller: TextEditingController(text: "kastanie.ddns.net:3000"),
                  )
               ),
            ],
         ),
      );

}
