
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StreamedProxyProvider<Src, Res, El> extends StatefulWidget {

	final Widget child;
	final Stream<El> Function(Src) stream;
	final Res Function(Src) create;

  const StreamedProxyProvider({
	  super.key,
	  required this.child,
	  required this.stream,
	  required this.create,
	});

	@override
	State<StreamedProxyProvider<Src, Res, El>> createState() => _TransformProviderState<Src, Res, El>();
}

class _TransformProviderState<Src, Res, El> extends State<StreamedProxyProvider<Src, Res, El>> {

	El? el;
	StreamSubscription? _sub;

	@override
	void dispose() {
		_sub?.cancel();
		super.dispose();
	}

	@override
	Widget build(BuildContext ctx) {
		var src = ctx.read<Src>();
		var res = ctx.select<Src, Res>(widget.create);
		_sub?.cancel();
		_sub = widget.stream(src).listen((el) {
			setState(() {});
		});
		return Provider.value(
			value: res,
			child: widget.child,
		);
	}
}

class TimerList {

	List<DateTime> times = [];

	int get length => times.length;
	bool get isEmpty => times.isEmpty;
	bool get isNotEmpty => times.isNotEmpty;
	
	void addNow() {
		DateTime now = DateTime.now();
		now = now.subtract(Duration(milliseconds: now.millisecond));
		if (times.isNotEmpty) {
			int milliMin = times.last.millisecondsSinceEpoch + 1000;
			if (now.millisecondsSinceEpoch < milliMin) {
				now = DateTime.fromMillisecondsSinceEpoch(milliMin);
			}
		}
		times.add(now);
	}

	DateTime operator [](int i) => times[i];

}
