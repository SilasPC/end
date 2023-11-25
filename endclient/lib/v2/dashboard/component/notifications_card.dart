// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';

class NotificationsCard extends StatelessWidget {
  const NotificationsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
    	color: Colors.black26,
    	child: SizedBox(
    		width: 250,
    		child: Column(
    			children: [
    				Container(
    					alignment: Alignment.center,
    					padding: const EdgeInsets.all(8),
    					child: Text(
    						"Notifications",
    						style: TextStyle(
    							fontSize: 20
    						)
    					),
    				),
    				Divider(),
    				Container(
    					decoration: BoxDecoration(
    						border: Border.all(
    							color: Colors.green,
    						),
    						borderRadius: BorderRadius.circular(8)
    					),
    					child: ListTile(
    						title: Text("MA finished!"),
    						subtitle: Text("Results available"),
    						trailing: IconButton(
    							splashRadius: 16,
    							color: Colors.white30,
    							icon: Icon(Icons.close),
    							onPressed: () {},
    						),
    					),
    				),
    				ListTile(
    					title: Text("Warning"),
    					subtitle: Text("203 late start"),
    					trailing: IconButton(
    						splashRadius: 16,
    						color: Colors.white30,
    						icon: Icon(Icons.close),
    						onPressed: () {},
    					),
    				),
    			],
    		),
    	)
    );
  }
}
