
import 'package:esys_client/service_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class A {
	int a = 0;
	ValueNotifier<C> c = ValueNotifier(C(0));
	void inc() {
		c.value = C(c.value.c+1);
	}
}

class B extends ChangeNotifier {

	final int a;
	int b = 0;

	B(this.a) {
		print("init B");
	}

	void inc() {
		b++;
		notifyListeners();
	}

}

class C {
	final int c;
	C(this.c);
}

void main() {
	testWidgets('service graph', (WidgetTester tester) async {

		var g = ServiceGraph();

		g.add(A());
		g.addListenableDep((A a) => B(a.a));
		g.deriveListenable((A a) => a.c);

		g.pipe((A a, C c) {
			a.a = c.c * c.c;
		});

		await tester.pump();

		expect(g.get<A>().value, isA<A>());
		expect(g.get<B>().value, isA<B>());
		expect(g.get<C>().value, isA<C>());

		await tester.pumpWidget(
			MaterialApp(
				home: ServiceGraphProvider.value(
					graph: g,
					child: Builder(
						builder: (context) {
							var valc = context.select((A a) => a.c.value);
							var val = context.select((B b) => "${b.a} ${b.b} $valc");
							return Text(val);
						},
					),
				)
			)
		);

		expect(find.text("0 0 0"), findsOneWidget);

		g.get<B>().value!.inc();
		await tester.pumpAndSettle();
		expect(find.text("0 1 0"), findsOneWidget);

		g.get<A>().value!.inc();
		await tester.pumpAndSettle();
		expect(find.text("1 1 1"), findsOneWidget);
		
		g.get<A>().value!.inc();
		await tester.pumpAndSettle();
		expect(find.text("4 1 2"), findsOneWidget);

		

	});
}
