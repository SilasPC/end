
import 'package:common/models/glob.dart';
import 'package:flutter/material.dart';

class EquipageTile extends StatelessWidget {

	static const double height = 64;

	final VoidCallback? onTap;
	final VoidCallback? onLongPress;
	final Equipage equipage;
	final Widget? leading;
	final List<Widget> trailing;
	final Color? color;

	const EquipageTile(this.equipage, {super.key, this.onTap, this.onLongPress, this.leading, this.trailing = const [], this.color});

	@override
	Widget build(BuildContext context) => 
		GestureDetector(
			behavior: HitTestBehavior.opaque,
			onTap: onTap,
			onLongPress: onLongPress,
			child: Container(
				color: color,
				padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
				height: EquipageTile.height,
				child: Row(
					mainAxisAlignment: MainAxisAlignment.start,
					children: [
						if (leading != null)
							leading!,
						const SizedBox(width: 10),
						Flexible(
							fit: FlexFit.tight,
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const SizedBox(height: 5),
									Text("${equipage.eid} ${equipage.rider}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
									Text(equipage.horse, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12),),
								],
							),
						),
						//const Spacer(),
						Column(
							mainAxisAlignment: MainAxisAlignment.center,
							children: [
								Text(equipage.status.name),
								if (equipage.currentLoop != null)
								Text("Loop ${equipage.currentLoop! + 1}")
							],
						),
						...trailing
					],
				)
			)
		);

}
