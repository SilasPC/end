
import 'package:esys_client/service_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class A {
	int a;
	A(this.a);
	ValueNotifier<C> c = ValueNotifier(C(0));
	void inc() {
		c.value = C(c.value.c+1);
	}
}

class B extends ChangeNotifier {

	final int a;
	int b = 0;

	B(this.a);

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

		g.add(A(0));
		g.addListenableDep((A a) => B(a.a));
		g.deriveListenable((A a) => a.c);

		g.pipe((C c, A a) {
			a.a = c.c * c.c;
		});

		await tester.pump();

		expect(g.read<A>(), isA<A>());
		expect(g.read<B>(), isA<B>());
		expect(g.read<C>(), isA<C>());

		await tester.pumpWidget(
			MaterialApp(
				home: ServiceGraphProvider.value(
					graph: g,
					child: Builder(
						builder: (context) {
							A a = context.watch();
							B b = context.watch();
							C c = context.watch();
							var txt = "${a.a}/${b.a} ${b.b} ${c.c}";
							print(txt);
							return Text(txt);
						},
					),
				)
			)
		);

		expect(find.text("0/0 0 0"), findsOneWidget);

		g.read<B>().inc();
		await tester.pumpAndSettle();
		expect(find.text("0/0 1 0"), findsOneWidget);

		g.read<A>().inc();
		await tester.pumpAndSettle();
		expect(find.text("1/0 1 1"), findsOneWidget);
		
		g.read<A>().inc();
		await tester.pumpAndSettle();
		expect(find.text("4/0 1 2"), findsOneWidget);

		g.get<A>().write(A(1));
		await tester.pumpAndSettle();
		expect(find.text("0/1 0 0"), findsOneWidget);

		g.read<A>().inc();
		g.read<A>().inc();
		await tester.pumpAndSettle();
		expect(find.text("4/1 0 2"), findsOneWidget);

	});
}
