
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {

   const SettingsPage({super.key});

   @override
   Widget build(BuildContext context) =>
      Scaffold(
         appBar: AppBar(
            title: const Text("Settings"),
         ),
         body: ListView(
            children: const [
               ListTile(
                  title: Text("Reset model"),
               ),
               ListTile(
                  title: TextField(
                     
                  )
               ),
            ],
         ),
      );

}