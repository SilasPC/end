
// TODO: deprecate
class Tuple<A,B> {
	final A a;
	final B b;
	Tuple(this.a,this.b);
	@override
	String toString() => "Tuple($a, $b)";
}

class Tuple3<A,B,C> {
	final A a;
	final B b;
	final C c;
	Tuple3(this.a,this.b,this.c);
	@override
	String toString() => "Tuple3($a, $b, $c)";
}
