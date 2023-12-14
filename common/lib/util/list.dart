
bool listEq(List a, List b) {
	if (a.length != b.length) return false;
	for (int i = 0; i < a.length; i++) {
		if (a[i] != b[i]) return false;
	}
	return true;
}

/**
 * Return the index of the first element for which `p` is true.
 * `p` should thus return true for the tail of the list.
 */
int binarySearch<T>(List<T> list, bool Function(T) p) {
	if (list.isEmpty) return -1;
	int low = 0, hgh = list.length - 1;
	while (low < hgh) {
		int mid = ((low+hgh)/2).floor();
		if (p(list[mid])) {
			hgh = mid;
		} else {
			low = mid + 1;
		}
	}
	return p(list[low]) ? low : -1;
}

/**
 * Return the index of the last element for which `p` is true.
 * `p` should thus return false for the tail of the list.
 */
int binarySearchLast<T>(List<T> list, bool Function(T) p) {
	if (list.isEmpty) return -1;
	int low = 0, hgh = list.length - 1;
	while (low < hgh) {
		int mid = ((low+hgh)/2).ceil();
		if (p(list[mid])) {
			low = mid;
		} else {
			hgh = mid - 1;
		}
	}
	return p(list[low]) ? low : -1;
}

List<T> reorder<T>(int i, int j, List<T> lst) {
	if (j > i) j--;
	return lst..insert(j, lst.removeAt(i));
}

List<T> swap<T>(int i, int j, List<T> lst) {
	var e = lst[i];
	lst[i] = lst[j];
	lst[j] = e;
	return lst;
}

/// Returns an index mapping `map`, such that the index of `list[i]`,
/// were it to be sorted, would be `map[i]`.
/// 
/// Thus the map provides the actual index the elements would recieve if sorted.
List<int> sortIndexMap<T>(List<T> list, Comparator<T> cmp) {
	var indices = List.generate(list.length, (index) => index)
		..sort((a, b) => cmp(list[a], list[b]));
	var map = List.filled(list.length, 0);
	for (int i = 0; i < list.length; i++) {
		map[indices[i]] = i;
	}
	return map;
}
