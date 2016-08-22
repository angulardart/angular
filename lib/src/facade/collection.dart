import 'dart:convert' show JsonEncoder;
export 'dart:core' show Iterator, Map, List, Set;

var jsonEncoder = new JsonEncoder();

typedef bool Predicate<T>(T item);

bool isListLikeIterable(obj) => obj is Iterable;

bool areIterablesEqual/*<T>*/(
    Iterable/*<T>*/ a, Iterable/*<T>*/ b, bool comparator(/*=T*/ a, /*=T*/ b)) {
  var iterator1 = a.iterator;
  var iterator2 = b.iterator;

  while (true) {
    var done1 = !iterator1.moveNext();
    var done2 = !iterator2.moveNext();
    if (done1 && done2) return true;
    if (done1 || done2) return false;
    if (!comparator(iterator1.current, iterator2.current)) return false;
  }
}

void iterateListLike/*<T>*/(Iterable/*<T>*/ iter, fn(/*=T*/ item)) {
  assert(iter is Iterable);
  for (var item in iter) {
    fn(item);
  }
}

class SetWrapper {
  static Set/*<T>*/ createFromList/*<T>*/(List/*<T>*/ l) => new Set.from(l);
  static bool has/*<T>*/(Set/*<T>*/ s, /*=T*/ key) => s.contains(key);
  static void delete/*<T>*/(Set/*<T>*/ m, /*=T*/ k) {
    m.remove(k);
  }
}
