import 'package:esys_client/consts.dart';
import 'package:flutter/material.dart';

Widget listGroupHeader(String label) => Row(children: [
      const Expanded(
          child: Divider(
        color: black27,
        indent: 16,
        endIndent: 16,
      )),
      Text(label,
          /* textAlign: TextAlign.center, */
          style: const TextStyle(
              /* fontSize: 20, */
              fontWeight: FontWeight.bold,
              color: black27)),
      const Expanded(
          child: Divider(
        color: black27,
        indent: 16,
        endIndent: 16,
      ))
    ]);

List<Widget> cardHeader(String label) => [
      Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 20)),
      ),
      const Divider(),
    ];

List<Widget> cardHeaderWithTrailing(String label, List<Widget> trailing) => [
      Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: trailing,
          ),
        ],
      ),
      const Divider()
    ];

Widget coloredCardheader(BuildContext context, String label) {
  var shape = CardTheme.of(context).shape;
  BorderRadius? borderRadius;
  if (shape
      case RoundedRectangleBorder(
        borderRadius: BorderRadius(:var topLeft, :var topRight)
      ) when topLeft == topRight) {
    borderRadius = BorderRadius.vertical(top: topLeft);
  }
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.black26, // IGNORED: UI: theme
      ),
      child: Text(label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 20,
          )));
}

Widget labelIconButton(String text, IconData icon, {VoidCallback? onPressed}) =>
    ElevatedButton(
      // style: ElevatedButton.styleFrom(backgroundColor: Colors.black38.withAlpha(200)),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 6),
          Icon(icon),
        ],
      ),
    );

Widget emptyListText(String label) => Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 16),
      child: Text(label,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          )),
    );
