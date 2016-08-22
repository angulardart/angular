import 'dart:collection';

import 'package:angular2/src/facade/async.dart';

/**
 * See query_list.ts
 */
class QueryList<T> extends Object with IterableMixin<T> {
  bool _dirty = true;
  List<T> _results = [];
  EventEmitter<Iterable<T>> _emitter = new EventEmitter<Iterable<T>>();

  Iterator<T> get iterator => _results.iterator;

  Stream<Iterable<T>> get changes => _emitter;

  int get length => _results.length;
  T get first => _results.length > 0 ? _results.first : null;
  T get last => _results.length > 0 ? _results.last : null;
  String toString() {
    return _results.toString();
  }

  /** @internal */
  void reset(List newList) {
    // This used to call ListWrapper.flatten(newList). Let's inline it for now.
    var results = <T>[];
    _flattenList(results, newList);
    _results = results;
    _dirty = false;
  }

  /** @internal */
  void notifyOnChanges() {
    _emitter.add(this);
  }

  /** @internal **/
  bool get dirty => _dirty;

  /** @internal **/
  void setDirty() {
    _dirty = true;
  }
}

void _flattenList(List results, Iterable items) {
  for (var item in items) {
    if (item is Iterable) {
      _flattenList(results, item);
    } else {
      results.add(item);
    }
  }
}
