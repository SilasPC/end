import 'package:flutter/material.dart';

class ChipStrip extends StatelessWidget {
  final List<Widget> chips;
  final Decoration? decoration;

  const ChipStrip({super.key, required this.chips, this.decoration});

  @override
  Widget build(BuildContext context) => Container(
      height: 50,
      padding: const EdgeInsets.only(right: 10),
      decoration: decoration,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var chip in chips)
            Padding(padding: const EdgeInsets.only(left: 10), child: chip)
        ],
      ));
}
