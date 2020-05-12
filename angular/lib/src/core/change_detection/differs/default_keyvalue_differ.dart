class DefaultKeyValueDiffer {
  final _records = <dynamic, KeyValueChangeRecord>{};
  KeyValueChangeRecord _mapHead;

  KeyValueChangeRecord _appendAfter;

  KeyValueChangeRecord _previousMapHead;

  KeyValueChangeRecord _changesHead;
  KeyValueChangeRecord _changesTail;

  KeyValueChangeRecord _additionsHead;
  KeyValueChangeRecord _additionsTail;

  KeyValueChangeRecord _removalsHead;

  bool get isDirty {
    return !identical(_additionsHead, null) ||
        !identical(_changesHead, null) ||
        !identical(_removalsHead, null);
  }

  void forEachChangedItem(void Function(KeyValueChangeRecord) fn) {
    for (var record = _changesHead;
        !identical(record, null);
        record = record._nextChanged) {
      fn(record);
    }
  }

  void forEachAddedItem(void Function(KeyValueChangeRecord) fn) {
    for (var record = _additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      fn(record);
    }
  }

  void forEachRemovedItem(void Function(KeyValueChangeRecord) fn) {
    for (var record = _removalsHead;
        !identical(record, null);
        record = record._next) {
      fn(record);
    }
  }

  DefaultKeyValueDiffer diff(Map<Object, Object> map) {
    map ??= {};
    if (map is! Map<Object, Object>) {
      throw StateError("Error trying to diff '$map'");
    }
    if (check(map)) {
      return this;
    } else {
      return null;
    }
  }

  /// Check for differences in [map] since the previous invocation.
  ///
  /// Optimized for no key changes.
  bool check(Map<Object, Object> map) {
    _reset();

    if (_mapHead == null) {
      // Optimize initial add.
      map.forEach((key, value) {
        var record = KeyValueChangeRecord(key)..currentValue = value;
        _records[key] = record;
        _addToAdditions(record);

        if (_appendAfter == null) {
          _mapHead = record;
        } else {
          record._prev = _appendAfter;
          _appendAfter._next = record;
        }

        _appendAfter = record;
      });

      return _mapHead != null;
    }

    var insertBefore = _mapHead;

    map.forEach((key, value) {
      if (insertBefore?.key == key) {
        _maybeAddToChanges(insertBefore, value);
        _appendAfter = insertBefore;
        insertBefore = insertBefore._next;
      } else {
        var record = _getOrCreateRecord(key, value);
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
        _removalsHead._prev._next = null;
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

    var record = KeyValueChangeRecord(key)..currentValue = value;
    _records[key] = record;
    _addToAdditions(record);
    return record;
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

    if (isDirty) {
      // Map state before changes.
      _previousMapHead = _mapHead;

      for (var record = _previousMapHead;
          record != null;
          record = record._next) {
        record._nextPrevious = record._next;
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
  }

  void _addToAdditions(KeyValueChangeRecord record) {
    // todo(vicb): assert

    // assert(record._next == null);

    // assert(record._nextAdded == null);

    // assert(record._nextChanged == null);

    // assert(record._nextRemoved == null);

    // assert(record._prevRemoved == null);
    if (identical(_additionsHead, null)) {
      _additionsHead = _additionsTail = record;
    } else {
      _additionsTail._nextAdded = record;
      _additionsTail = record;
    }
  }

  void _addToChanges(KeyValueChangeRecord record) {
    // todo(vicb) assert

    // assert(record._nextAdded == null);

    // assert(record._nextChanged == null);

    // assert(record._nextRemoved == null);

    // assert(record._prevRemoved == null);
    if (identical(_changesHead, null)) {
      _changesHead = _changesTail = record;
    } else {
      _changesTail._nextChanged = record;
      _changesTail = record;
    }
  }

  @override
  String toString() {
    var items = <Object>[];
    var previous = <Object>[];
    var changes = <Object>[];
    var additions = <Object>[];
    var removals = <Object>[];
    for (var record = _mapHead;
        !identical(record, null);
        record = record._next) {
      items.add(record);
    }
    for (var record = _previousMapHead;
        !identical(record, null);
        record = record._nextPrevious) {
      previous.add(record);
    }
    for (var record = _changesHead;
        !identical(record, null);
        record = record._nextChanged) {
      changes.add(record);
    }
    for (var record = _additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      additions.add(record);
    }
    for (var record = _removalsHead;
        !identical(record, null);
        record = record._next) {
      removals.add(record);
    }
    return 'map: ' +
        items.join(', ') +
        '\n' +
        'previous: ' +
        previous.join(', ') +
        '\n' +
        'additions: ' +
        additions.join(', ') +
        '\n' +
        'changes: ' +
        changes.join(', ') +
        '\n' +
        'removals: ' +
        removals.join(', ') +
        '\n';
  }
}

class KeyValueChangeRecord {
  dynamic key;
  dynamic previousValue;
  dynamic currentValue;

  KeyValueChangeRecord _nextPrevious;

  KeyValueChangeRecord _next;

  KeyValueChangeRecord _prev;

  KeyValueChangeRecord _nextAdded;

  KeyValueChangeRecord _nextChanged;

  KeyValueChangeRecord(this.key);
  @override
  String toString() {
    return identical(previousValue, currentValue)
        ? '$key'
        : '$key[$previousValue->$currentValue]';
  }
}
