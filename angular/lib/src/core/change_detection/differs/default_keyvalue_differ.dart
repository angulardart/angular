import 'dart:collection';

class DefaultKeyValueDiffer {
  final _records = LinkedHashMap<Object?, KeyValueChangeRecord>.identity();

  KeyValueChangeRecord? _mapHead;
  KeyValueChangeRecord? _appendAfter;
  KeyValueChangeRecord? _changesHead;
  KeyValueChangeRecord? _changesTail;
  KeyValueChangeRecord? _additionsHead;
  KeyValueChangeRecord? _additionsTail;
  KeyValueChangeRecord? _removalsHead;

  /// Whether [_additionsHead], [_changesHead], or [_removalsHead] is set.
  bool get _isDirty =>
      _additionsHead != null || _changesHead != null || _removalsHead != null;

  /// Invokes [fn] for every changed item since last check.
  void forEachChangedItem(void Function(KeyValueChangeRecord) fn) {
    for (var record = _changesHead;
        record != null;
        record = record._nextChanged) {
      fn(record);
    }
  }

  /// Invokes [fn] for every added item since last check.
  void forEachAddedItem(void Function(KeyValueChangeRecord) fn) {
    for (var record = _additionsHead;
        record != null;
        record = record._nextAdded) {
      fn(record);
    }
  }

  /// Invokes [fn] for every removed item since last check.
  void forEachRemovedItem(void Function(KeyValueChangeRecord) fn) {
    for (var record = _removalsHead; record != null; record = record._next) {
      fn(record);
    }
  }

  /// Check for differences in [map] since the previous invocation.
  ///
  /// Optimized for no key changes.
  bool diff(Map<Object?, Object?>? map) {
    map ??= const {};
    _reset();

    if (_mapHead == null) {
      // Optimize initial add.
      map.forEach((key, value) {
        final record = KeyValueChangeRecord._(key, value);
        _records[key] = record;
        _addToAdditions(record);

        if (_appendAfter == null) {
          _mapHead = record;
        } else {
          record._prev = _appendAfter;
          _appendAfter!._next = record;
        }

        _appendAfter = record;
      });
      return _mapHead != null;
    }

    var insertBefore = _mapHead;
    map.forEach((key, value) {
      final insertBefore_ = insertBefore;
      if (insertBefore_ != null && insertBefore_.key == key) {
        _maybeAddToChanges(insertBefore_, value);
        _appendAfter = insertBefore_;
        insertBefore = insertBefore_._next;
      } else {
        final record = _getOrCreateRecord(key, value);
        insertBefore = _insertBeforeOrAppend(insertBefore, record);
      }
    });

    if (insertBefore != null) {
      // Remaining records that weren't seen are the removals.
      _removalsHead = insertBefore;

      for (var record = insertBefore; record != null; record = record._next) {
        _records.remove(record.key);
        record.previousValue = record.currentValue;
        record.currentValue = null;
      }

      if (_removalsHead == _mapHead) {
        // Remove the head record reference.
        _mapHead = null;
      } else {
        // Truncate removals from end of record list.
        _removalsHead!._prev!._next = null;
      }
    }

    return _isDirty;
  }

  /// Inserts a record before [before] or appends if [before] is null.
  ///
  /// Returns the new insertion pointer.
  KeyValueChangeRecord? _insertBeforeOrAppend(
    KeyValueChangeRecord? before,
    KeyValueChangeRecord record,
  ) {
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

    final appendAfter = _appendAfter;
    if (appendAfter != null) {
      appendAfter._next = record;
      record._prev = appendAfter;
    } else {
      _mapHead = record;
    }

    _appendAfter = record;
    return null;
  }

  KeyValueChangeRecord _getOrCreateRecord(Object? key, Object? value) {
    var record = _records[key];
    if (record != null) {
      _maybeAddToChanges(record, value);
      record._prev?._next = record._next;
      record._next?._prev = record._prev;
      record._prev = null;
      record._next = null;
      return record;
    } else {
      record = KeyValueChangeRecord._(key, value);
      _records[key] = record;
      _addToAdditions(record);
      return record;
    }
  }

  void _maybeAddToChanges(KeyValueChangeRecord record, dynamic value) {
    if (!identical(value, record.currentValue)) {
      record.previousValue = record.currentValue;
      record.currentValue = value;
      _addToChanges(record);
    }
  }

  void _reset() {
    _appendAfter = null;

    if (!_isDirty) {
      return;
    }

    for (var record = _changesHead;
        record != null;
        record = record._nextChanged) {
      record.previousValue = record.currentValue;
    }

    for (var record = _additionsHead;
        record != null;
        record = record._nextAdded) {
      record.previousValue = record.currentValue;
    }

    _changesHead = _changesTail = null;
    _additionsHead = _additionsTail = null;
    _removalsHead = null;
  }

  void _addToAdditions(KeyValueChangeRecord record) {
    if (_additionsHead == null) {
      _additionsHead = _additionsTail = record;
    } else {
      _additionsTail!._nextAdded = record;
      _additionsTail = record;
    }
  }

  void _addToChanges(KeyValueChangeRecord record) {
    if (_changesHead == null) {
      _changesHead = _changesTail = record;
    } else {
      _changesTail!._nextChanged = record;
      _changesTail = record;
    }
  }
}

class KeyValueChangeRecord {
  Object? key;
  Object? currentValue;
  Object? previousValue;

  KeyValueChangeRecord? _next;
  KeyValueChangeRecord? _prev;
  KeyValueChangeRecord? _nextAdded;
  KeyValueChangeRecord? _nextChanged;

  KeyValueChangeRecord._(this.key, this.currentValue);
}
