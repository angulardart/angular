import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import 'package:angular2/src/facade/lang.dart' show looseIdentical;

class DefaultKeyValueDiffer {
  Map<dynamic, dynamic> _records = new Map();
  KeyValueChangeRecord _mapHead;

  KeyValueChangeRecord _appendAfter;

  KeyValueChangeRecord _previousMapHead;

  KeyValueChangeRecord _changesHead;
  KeyValueChangeRecord _changesTail;

  KeyValueChangeRecord _additionsHead;
  KeyValueChangeRecord _additionsTail;

  KeyValueChangeRecord _removalsHead;
  KeyValueChangeRecord _removalsTail;

  bool get isDirty {
    return !identical(this._additionsHead, null) ||
        !identical(this._changesHead, null) ||
        !identical(this._removalsHead, null);
  }

  void forEachItem(Function fn) {
    KeyValueChangeRecord record;
    for (record = this._mapHead;
        !identical(record, null);
        record = record._next) {
      fn(record);
    }
  }

  void forEachPreviousItem(Function fn) {
    KeyValueChangeRecord record;
    for (record = this._previousMapHead;
        !identical(record, null);
        record = record._nextPrevious) {
      fn(record);
    }
  }

  void forEachChangedItem(Function fn) {
    KeyValueChangeRecord record;
    for (record = this._changesHead;
        !identical(record, null);
        record = record._nextChanged) {
      fn(record);
    }
  }

  void forEachAddedItem(Function fn) {
    KeyValueChangeRecord record;
    for (record = this._additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      fn(record);
    }
  }

  void forEachRemovedItem(Function fn) {
    KeyValueChangeRecord record;
    for (record = this._removalsHead;
        !identical(record, null);
        record = record._nextRemoved) {
      fn(record);
    }
  }

  dynamic diff(Map map) {
    map ??= {};
    if (map is! Map) {
      throw new BaseException('''Error trying to diff \'${ map}\'''');
    }
    if (this.check(map)) {
      return this;
    } else {
      return null;
    }
  }

  /// Check for differences in [map] since the previous invocation.
  ///
  /// Optimized for no key changes.
  bool check(Map<dynamic, dynamic> map) {
    _reset();

    var insertBefore = _mapHead;
    _appendAfter = null;

    _forEach(map, (value, key) {
      if (insertBefore?.key == key) {
        _maybeAddToChanges(insertBefore, value);
        _appendAfter = insertBefore;
        insertBefore = insertBefore._next;
      } else {
        var record = _getOrCreateRecord(key, value);
        insertBefore = _insertBeforeOrAppend(insertBefore, record);
      }
    });

    // Items remaining at the end of the list have been removed.
    if (insertBefore != null) {
      // Truncate end of list.
      insertBefore._prev?._next = null;

      _removalsHead = insertBefore;
      _removalsTail = insertBefore;

      if (_removalsHead == _mapHead) {
        _mapHead = null;
      }

      for (var record = insertBefore;
          record != null;
          record = record._nextRemoved) {
        _records.remove(record.key);
        record._nextRemoved = record._next;
        record.previousValue = record.currentValue;
        record.currentValue = null;
        record._prev = null;
        record._next = null;
      }
    }

    return isDirty;
  }

  /// Inserts a record before [before] or appends if [before] is null.
  ///
  /// Returns the new insertion pointer.
  KeyValueChangeRecord _insertBeforeOrAppend(
      KeyValueChangeRecord before, KeyValueChangeRecord record) {
    if (before != null) {
      record._next = before;
      record._prev = before._prev;
      before._prev?._next = record;
      before._prev = record;
      if (before == _mapHead) {
        _mapHead = record;
      }

      _appendAfter = before;
      return before;
    }

    if (_appendAfter != null) {
      _appendAfter._next = record;
      record._prev = _appendAfter;
    } else {
      _mapHead = record;
    }

    _appendAfter = record;
    return null;
  }

  KeyValueChangeRecord _getOrCreateRecord(key, value) {
    if (_records.containsKey(key)) {
      var record = _records[key];
      _maybeAddToChanges(record, value);
      record._prev?._next = record._next;
      record._next?._prev = record._prev;
      record._prev = null;
      record._next = null;
      return record;
    }

    var record = new KeyValueChangeRecord(key)..currentValue = value;
    _records[key] = record;
    _addToAdditions(record);
    return record;
  }

  void _maybeAddToChanges(KeyValueChangeRecord record, dynamic value) {
    if (!looseIdentical(value, record.currentValue)) {
      record.previousValue = record.currentValue;
      record.currentValue = value;
      _addToChanges(record);
    }
  }

  void _reset() {
    if (this.isDirty) {
      // Map state before changes.
      _previousMapHead = _mapHead;

      for (var record = this._previousMapHead;
          record != null;
          record = record._next) {
        record._nextPrevious = record._next;
      }

      for (var record = this._changesHead;
          record != null;
          record = record._nextChanged) {
        record.previousValue = record.currentValue;
      }

      for (var record = this._additionsHead;
          record != null;
          record = record._nextAdded) {
        record.previousValue = record.currentValue;
      }

      this._changesHead = this._changesTail = null;
      this._additionsHead = this._additionsTail = null;
      this._removalsHead = this._removalsTail = null;
    }
  }

  void _addToAdditions(KeyValueChangeRecord record) {
    // todo(vicb): assert

    // assert(record._next == null);

    // assert(record._nextAdded == null);

    // assert(record._nextChanged == null);

    // assert(record._nextRemoved == null);

    // assert(record._prevRemoved == null);
    if (identical(this._additionsHead, null)) {
      this._additionsHead = this._additionsTail = record;
    } else {
      this._additionsTail._nextAdded = record;
      this._additionsTail = record;
    }
  }

  void _addToChanges(KeyValueChangeRecord record) {
    // todo(vicb) assert

    // assert(record._nextAdded == null);

    // assert(record._nextChanged == null);

    // assert(record._nextRemoved == null);

    // assert(record._prevRemoved == null);
    if (identical(this._changesHead, null)) {
      this._changesHead = this._changesTail = record;
    } else {
      this._changesTail._nextChanged = record;
      this._changesTail = record;
    }
  }

  String toString() {
    var items = [];
    var previous = [];
    var changes = [];
    var additions = [];
    var removals = [];
    KeyValueChangeRecord record;
    for (record = this._mapHead;
        !identical(record, null);
        record = record._next) {
      items.add(record);
    }
    for (record = this._previousMapHead;
        !identical(record, null);
        record = record._nextPrevious) {
      previous.add(record);
    }
    for (record = this._changesHead;
        !identical(record, null);
        record = record._nextChanged) {
      changes.add(record);
    }
    for (record = this._additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      additions.add(record);
    }
    for (record = this._removalsHead;
        !identical(record, null);
        record = record._nextRemoved) {
      removals.add(record);
    }
    return "map: " +
        items.join(", ") +
        "\n" +
        "previous: " +
        previous.join(", ") +
        "\n" +
        "additions: " +
        additions.join(", ") +
        "\n" +
        "changes: " +
        changes.join(", ") +
        "\n" +
        "removals: " +
        removals.join(", ") +
        "\n";
  }

  void _forEach(obj, Function fn) {
    if (obj is Map) {
      obj.forEach((k, v) => fn(v, k));
    } else {
      var handler = fn as _MapHandler;
      (obj as Map<dynamic, String>).forEach(handler);
    }
  }
}

typedef void _MapHandler(dynamic value, String key);

class KeyValueChangeRecord {
  dynamic key;
  dynamic previousValue;
  dynamic currentValue;

  KeyValueChangeRecord _nextPrevious;

  KeyValueChangeRecord _next;

  KeyValueChangeRecord _prev;

  KeyValueChangeRecord _nextAdded;

  KeyValueChangeRecord _nextRemoved;

  KeyValueChangeRecord _nextChanged;
  KeyValueChangeRecord(this.key);
  String toString() {
    return looseIdentical(previousValue, currentValue)
        ? key
        : '$key[$previousValue->$currentValue]';
  }
}
