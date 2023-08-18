
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

	int? findOrdIndex(T t) {
		int i = _byOrd.indexWhere((e) => _cmp(e.a, t) == 0);
		// todo: fix
		//int i = binarySearch(_byOrd, (t0) => _cmp(t0.a,t) < 0);
		if (i == -1) return null;
		if (_cmp(_byOrd[i].a,t) == 0) return i;
		return null;
	}

	T byInsertionIndex(int i) => _byIns[i];

	int get length => _els.length;

	Iterable<T> get iteratorOrdered => _byOrd.map((e) => e.a);
	Iterable<T> get iteratorInsertion => _byIns;

}

bool _isBeforeOrSame<T extends Comparable<T>>(T t0, T t1)
	=>	t0.compareTo(t1) <= 0;
