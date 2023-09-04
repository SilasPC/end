
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SubmitButton extends StatefulWidget {

	final Duration? maxWait;
	final bool disabled;
	final Future Function() onPressed;

	const SubmitButton({required this.onPressed, this.disabled = false, this.maxWait = const Duration(seconds: 3), super.key});
	
	@override
	State<StatefulWidget> createState() => SubmitButtonState();
	
}

class SubmitButtonState extends State<SubmitButton> {

	bool loading = false;

	Future<void> onPressed() async {
		setState(() {
			loading = true;
		});
		await Future.any([
			widget.onPressed(),
			if (widget.maxWait != null)
				Future.delayed(widget.maxWait!)
		]);
		if (!mounted) return;
		setState(() {
			loading = false;
		});
	}
	
	@override
	Widget build(BuildContext context) {
		// TODO: fix icons (CircularProgressIndicator() ?)
		if (loading) {
			return Container(
				padding: const EdgeInsets.all(8),
				child: const Icon(Icons.update),
			);
		}
		return IconButton(
			onPressed: widget.disabled ? null : onPressed,
			icon: const Icon(Icons.send),
			color: Colors.green,
		);
	}
}
