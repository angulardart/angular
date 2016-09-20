import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show stringify, looseIdentical;

import "../change_detector_ref.dart" show ChangeDetectorRef;
import "../differs/keyvalue_differs.dart"
    show KeyValueDiffer, KeyValueDifferFactory;

class DefaultKeyValueDifferFactory implements KeyValueDifferFactory {
  bool supports(dynamic obj) => obj is Map;

  KeyValueDiffer create(ChangeDetectorRef cdRef) {
    return new DefaultKeyValueDiffer();
  }

  const DefaultKeyValueDifferFactory();
}

class DefaultKeyValueDiffer implements KeyValueDiffer<Map> {
  Map<dynamic, dynamic> _records = new Map();
  KeyValueChangeRecord _mapHead;
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

  void onDestroy() {}
  bool check(Map<dynamic, dynamic> map) {
    this._reset();
    var records = this._records;
    KeyValueChangeRecord oldSeqRecord = this._mapHead;
    KeyValueChangeRecord lastOldSeqRecord;
    KeyValueChangeRecord lastNewSeqRecord;
    bool seqChanged = false;
    this._forEach(map, (value, key) {
      var newSeqRecord;
      if (!identical(oldSeqRecord, null) && identical(key, oldSeqRecord.key)) {
        newSeqRecord = oldSeqRecord;
        if (!looseIdentical(value, oldSeqRecord.currentValue)) {
          oldSeqRecord.previousValue = oldSeqRecord.currentValue;
          oldSeqRecord.currentValue = value;
          this._addToChanges(oldSeqRecord);
        }
      } else {
        seqChanged = true;
        if (!identical(oldSeqRecord, null)) {
          oldSeqRecord._next = null;
          this._removeFromSeq(lastOldSeqRecord, oldSeqRecord);
          this._addToRemovals(oldSeqRecord);
        }
        if (records.containsKey(key)) {
          newSeqRecord = records[key];
        } else {
          newSeqRecord = new KeyValueChangeRecord(key);
          records[key] = newSeqRecord;
          newSeqRecord.currentValue = value;
          this._addToAdditions(newSeqRecord);
        }
      }
      if (seqChanged) {
        if (this._isInRemovals(newSeqRecord)) {
          this._removeFromRemovals(newSeqRecord);
        }
        if (lastNewSeqRecord == null) {
          this._mapHead = newSeqRecord;
        } else {
          lastNewSeqRecord._next = newSeqRecord;
        }
      }
      lastOldSeqRecord = oldSeqRecord;
      lastNewSeqRecord = newSeqRecord;
      oldSeqRecord = identical(oldSeqRecord, null) ? null : oldSeqRecord._next;
    });
    this._truncate(lastOldSeqRecord, oldSeqRecord);
    return this.isDirty;
  }

  void _reset() {
    if (this.isDirty) {
      KeyValueChangeRecord record;
      // Record the state of the mapping
      for (record = this._previousMapHead = this._mapHead;
          !identical(record, null);
          record = record._next) {
        record._nextPrevious = record._next;
      }
      for (record = this._changesHead;
          !identical(record, null);
          record = record._nextChanged) {
        record.previousValue = record.currentValue;
      }
      for (record = this._additionsHead;
          record != null;
          record = record._nextAdded) {
        record.previousValue = record.currentValue;
      }
      // todo(vicb) once assert is supported

      // assert(() {

      //  var r = _changesHead;

      //  while (r != null) {

      //    var nextRecord = r._nextChanged;

      //    r._nextChanged = null;

      //    r = nextRecord;

      //  }

      //

      //  r = _additionsHead;

      //  while (r != null) {

      //    var nextRecord = r._nextAdded;

      //    r._nextAdded = null;

      //    r = nextRecord;

      //  }

      //

      //  r = _removalsHead;

      //  while (r != null) {

      //    var nextRecord = r._nextRemoved;

      //    r._nextRemoved = null;

      //    r = nextRecord;

      //  }

      //

      //  return true;

      //});
      this._changesHead = this._changesTail = null;
      this._additionsHead = this._additionsTail = null;
      this._removalsHead = this._removalsTail = null;
    }
  }

  void _truncate(KeyValueChangeRecord lastRecord, KeyValueChangeRecord record) {
    while (!identical(record, null)) {
      if (identical(lastRecord, null)) {
        this._mapHead = null;
      } else {
        lastRecord._next = null;
      }
      var nextRecord = record._next;
      // todo(vicb) assert

      // assert((() {

      //  record._next = null;

      //  return true;

      //}));
      this._addToRemovals(record);
      lastRecord = record;
      record = nextRecord;
    }
    for (KeyValueChangeRecord rec = this._removalsHead;
        !identical(rec, null);
        rec = rec._nextRemoved) {
      rec.previousValue = rec.currentValue;
      rec.currentValue = null;
      (this._records.containsKey(rec.key) &&
          (this._records.remove(rec.key) != null || true));
    }
  }

  bool _isInRemovals(KeyValueChangeRecord record) {
    return identical(record, this._removalsHead) ||
        !identical(record._nextRemoved, null) ||
        !identical(record._prevRemoved, null);
  }

  void _addToRemovals(KeyValueChangeRecord record) {
    // todo(vicb) assert

    // assert(record._next == null);

    // assert(record._nextAdded == null);

    // assert(record._nextChanged == null);

    // assert(record._nextRemoved == null);

    // assert(record._prevRemoved == null);
    if (identical(this._removalsHead, null)) {
      this._removalsHead = this._removalsTail = record;
    } else {
      this._removalsTail._nextRemoved = record;
      record._prevRemoved = this._removalsTail;
      this._removalsTail = record;
    }
  }

  void _removeFromSeq(KeyValueChangeRecord prev, KeyValueChangeRecord record) {
    var next = record._next;
    if (identical(prev, null)) {
      this._mapHead = next;
    } else {
      prev._next = next;
    }
  }

  void _removeFromRemovals(KeyValueChangeRecord record) {
    // todo(vicb) assert

    // assert(record._next == null);

    // assert(record._nextAdded == null);

    // assert(record._nextChanged == null);
    var prev = record._prevRemoved;
    var next = record._nextRemoved;
    if (identical(prev, null)) {
      this._removalsHead = next;
    } else {
      prev._nextRemoved = next;
    }
    if (identical(next, null)) {
      this._removalsTail = prev;
    } else {
      next._prevRemoved = prev;
    }
    record._prevRemoved = record._nextRemoved = null;
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
      items.add(stringify(record));
    }
    for (record = this._previousMapHead;
        !identical(record, null);
        record = record._nextPrevious) {
      previous.add(stringify(record));
    }
    for (record = this._changesHead;
        !identical(record, null);
        record = record._nextChanged) {
      changes.add(stringify(record));
    }
    for (record = this._additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      additions.add(stringify(record));
    }
    for (record = this._removalsHead;
        !identical(record, null);
        record = record._nextRemoved) {
      removals.add(stringify(record));
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

  KeyValueChangeRecord _nextAdded;

  KeyValueChangeRecord _nextRemoved;

  KeyValueChangeRecord _prevRemoved;

  KeyValueChangeRecord _nextChanged;
  KeyValueChangeRecord(this.key);
  String toString() {
    return looseIdentical(this.previousValue, this.currentValue)
        ? stringify(this.key)
        : (stringify(this.key) +
            "[" +
            stringify(this.previousValue) +
            "->" +
            stringify(this.currentValue) +
            "]");
  }
}
