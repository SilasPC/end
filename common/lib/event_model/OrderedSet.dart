
import 'dart:collection';

import 'package:common/util.dart';

class OrderedSet<T> {

	final Comparator<T> _cmp;

	HashSet<T> _els = HashSet();
	List<Tuple<T,int>> _byOrd = [];
	List<T> _byIns = [];

	OrderedSet():
		_cmp = ((a, b) => (a as Comparable<T>).compareTo(b));

	OrderedSet.withComparator(this._cmp);

	void clear() {
		_els.clear();
		_byIns.clear();
		_byOrd.clear();
	}

	bool add(T t) {
		if (!_els.add(t)) return false;
		_byOrd
			..add(Tuple(t, _byIns.length))
			..sort((t0, t1) => _cmp(t0.a,t1.a));
		_byIns.add(t);
		return true;
	}

	void addAll(Iterable<T> ts) {
		for (var t in ts) add(t);	
	}

	/// converts to insertion index into the corresponding ordered index
	int? toOrdIndex(int insIdx) => findOrdIndex(byInsertionIndex(insIdx));

	/// finds the ordered index given an element
	int? findOrdIndex(T t) {
		int i = _byOrd.indexWhere((e) => _cmp(e.a, t) == 0);
		// PERF: binary search
		//int i = binarySearch(_byOrd, (t0) => _cmp(t0.a,t) < 0);
		if (i == -1) return null;
		if (_cmp(_byOrd[i].a,t) == 0) return i;
		return null;
	}

	/// find the element given the insertion index
	T byInsertionIndex(int i) => _byIns[i];

	bool get isEmpty => _els.isEmpty;
	bool get isNotEmpty => _els.isNotEmpty;
	int get length => _els.length;

	int? get lastInsertionIndex => _byOrd.isEmpty ? null : _byOrd.last.b;

	Iterable<T> get iterator => _byOrd.map((e) => e.a);
	Iterable<T> get iteratorInsertion => _byIns;

	T get last => _byOrd.last.a;
	T get first => _byOrd.first.a;

	int lastIndexWhere(Predicate<T> p) =>_byOrd.lastIndexWhere((e) => p(e.a));
	int indexWhere(Predicate<T> p) =>_byOrd.indexWhere((e) => p(e.a));

	T operator[] (int idx) => _byOrd[idx].a;

}

bool _isBeforeOrSame<T extends Comparable<T>>(T t0, T t1)
	=>	t0.compareTo(t1) <= 0;
