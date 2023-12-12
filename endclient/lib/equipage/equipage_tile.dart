
import 'package:common/models/glob.dart';
import 'package:flutter/material.dart';

class EquipageTile extends StatelessWidget {

	static const double height = 66;

	final VoidCallback? onTap;
	final VoidCallback? onLongPress;
	final Equipage equipage;
	final Widget? leading;
	final List<Widget> trailing;
	final Color? color;
	final bool noStatus;

	const EquipageTile(
		this.equipage, {
			super.key,
			this.onTap,
			this.onLongPress,
			this.leading,
			this.trailing = const [],
			this.color,
			this.noStatus = false
		}
	);

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
					crossAxisAlignment: CrossAxisAlignment.center,
					children: [
						if (leading case Widget leading)
							leading,
						const SizedBox(width: 10),
						Flexible(
							fit: FlexFit.tight,
							child: Column(
								mainAxisAlignment: MainAxisAlignment.center,
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text("${equipage.eid} ${equipage.rider}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
									Text(equipage.horse, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12),),
								],
							),
						),
						//const Spacer(),
						if (!noStatus) ...[
							Column(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Text(equipage.status.name),
									if (equipage.currentLoop case int currentLoop)
									if (!equipage.isEnded)
									Text("Loop ${currentLoop + 1}")
								],
							),
							const SizedBox(width: 10),
						],
						...trailing
					],
				)
			)
		);

}
