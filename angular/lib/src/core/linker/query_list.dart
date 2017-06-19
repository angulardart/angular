import 'dart:async';
import 'dart:collection';

/// A list of items that Angular keeps up to date when the state of the
/// application changes.
///
/// Provides  an observable list for references to child components requested
/// by @ViewChildren and @ViewChild annotations.
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
