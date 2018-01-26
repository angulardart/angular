import 'dart:async';
import 'dart:collection';

import '../metadata.dart' show ContentChildren, ViewChildren;

/// A legacy (now deprecated) way to receive updates on child elements.
///
/// See [ViewChildren] and [ContentChildren], and the markdown document titled
/// `deprecated_query_list.md` for additional examples and rationale for the
/// deprecation.
@Deprecated('Use a normal List instead. See comments for details')
class QueryList<T> extends Object with IterableMixin<T> {
  bool _dirty = true;
  List<T> _results = const [];
  StreamController<Iterable<T>> _streamController;

  @override
  Iterator<T> get iterator => _results.iterator;

  Stream<Iterable<T>> get changes {
    _streamController ??= new StreamController<Iterable<T>>.broadcast();
    return _streamController.stream;
  }

  int get length => _results.length;
  T get first => _results.isNotEmpty ? _results.first : null;
  T get last => _results.isNotEmpty ? _results.last : null;

  String toString() {
    return _results.toString();
  }

  /// Called internally by AppView to initialize list of view children.
  void reset(List<T> newList) {
    int itemCount = newList.length;
    for (int i = 0; i < itemCount; i++) {
      if (newList[i] is List) {
        var results = <T>[];
        _flattenList(newList, results);
        _results = results;
        _dirty = false;
        return;
      }
    }
    _results = newList;
    _dirty = false;
  }

  /// Called internally by AppView when list has changed.
  void notifyOnChanges() {
    _streamController ??= new StreamController<Iterable<T>>.broadcast();
    _streamController.add(this);
  }

  bool get dirty => _dirty;

  void setDirty() {
    _dirty = true;
  }
}

void _flattenList(List items, List results) {
  int itemCount = items.length;
  for (int i = 0; i < itemCount; i++) {
    var item = items[i];
    if (item is List) {
      _flattenList(item, results);
    } else {
      results.add(item);
    }
  }
}
