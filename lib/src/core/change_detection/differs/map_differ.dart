import 'package:angular2/src/facade/lang.dart' show looseIdentical;

/// Handles added or changed [key]-[value] pair.
typedef void MapChangeHandler<K, V>(K key, V value);

/// Handles removed [key].
typedef void MapRemovalHandler<K>(K key);

/// Finds the differences in a [Map] between subsequent checks.
class MapDiffer<K, V> {
  /// Records from previous invocation of [diff] for efficient lookup.
  Map<K, _MapChangeRecord<K, V>> _records = <K, _MapChangeRecord<K, V>>{};

  /// Linked list of records from previous invocation of [diff] for efficient
  /// iteration.
  _MapChangeRecord<K, V> _headRecord;

  /// Linked list of added or changed records.
  _MapChangeRecord<K, V> _headChange;

  /// Linked list of removed records.
  _MapChangeRecord<K, V> _headRemoval;

  /// Returns true if [map] has differences since the last invocation.
  bool diff(Map<K, V> map) {
    map ??= <K, V>{};

    // Reset changes.
    _headChange = null;
    _headRemoval = null;

    // Used to append to tail of map records.
    var tailRecord;

    // Optimize initial add.
    if (_headRecord == null) {
      for (var key in map.keys) {
        var record = _records[key] = new _MapChangeRecord<K, V>(key, map[key]);

        if (tailRecord == null) {
          _headRecord = record;
          _headChange = record;
        } else {
          record.prev = tailRecord;
          tailRecord.next = record;
          tailRecord.nextChange = record;
        }

        tailRecord = record;
      }

      return _headChange != null;
    }

    // The record expected to be next assuming no changes.
    var nextExpectedRecord = _headRecord;

    for (var key in map.keys) {
      if (key == nextExpectedRecord?.key) {
        // Expected record is in sequence, update if necessary.
        _maybeAddChange(nextExpectedRecord, map[key]);
        tailRecord = nextExpectedRecord;
        nextExpectedRecord = nextExpectedRecord.next;
      } else {
        // The record for [key] is new or has moved.
        var record = _getOrCreateRecord(key, map[key]);
        if (nextExpectedRecord != null) {
          // Insert new or moved record before the next expected record.
          record.next = nextExpectedRecord;
          record.prev = nextExpectedRecord.prev;
          nextExpectedRecord.prev?.next = record;
          nextExpectedRecord.prev = record;
          tailRecord = nextExpectedRecord;
          if (nextExpectedRecord == _headRecord) {
            _headRecord = record;
          }
        } else if (tailRecord != null) {
          // All expected records have been seen; append new record.
          record.prev = tailRecord;
          record.next = null;
          tailRecord.next = record;
          tailRecord = record;
        }
      }
    }

    if (nextExpectedRecord != null) {
      // Remaining expected records that weren't seen are the removals.
      _headRemoval = nextExpectedRecord;

      // Update [_records] for next invocation.
      for (var record = _headRemoval; record != null; record = record.next) {
        _records.remove(record.key);
      }

      if (_headRemoval == _headRecord) {
        // Remove the head record reference.
        _headRecord = null;
      } else {
        // Truncate removals from end of record list.
        _headRemoval.prev.next = null;
      }
    }

    return _headChange != null || _headRemoval != null;
  }

  /// Invokes [fn] with each added or changed key-value pair.
  void forEachChange(MapChangeHandler<K, V> fn) {
    for (var record = _headChange; record != null; record = record.nextChange) {
      fn(record.key, record.value);
    }
  }

  /// Invokes [fn] with each removed key.
  void forEachRemoval(MapRemovalHandler<K> fn) {
    for (var record = _headRemoval; record != null; record = record.next) {
      fn(record.key);
    }
  }

  /// Adds [record] to the change list.
  void _addChange(_MapChangeRecord<K, V> record) {
    record.nextChange = _headChange;
    _headChange = record;
  }

  /// Removes record from list if it exists, or creates one.
  _MapChangeRecord<K, V> _getOrCreateRecord(K key, V value) {
    var record;

    if (_records.containsKey(key)) {
      // Retrieve existing record.
      record = _records[key];

      // Remove record from current position in list.
      record.prev?.next = record.next;
      record.next?.prev = record.prev;

      _maybeAddChange(record, value);
    } else {
      record = _records[key] = new _MapChangeRecord(key, value);
      _addChange(record);
    }

    return record;
  }

  /// Adds [record] to change list if its value differs from [value].
  void _maybeAddChange(_MapChangeRecord<K, V> record, V value) {
    if (!looseIdentical(record.value, value)) {
      record.value = value;
      _addChange(record);
    }
  }
}

class _MapChangeRecord<K, V> {
  final K key;
  V value;

  /// Used for change detection and iterating removals.
  _MapChangeRecord<K, V> next;

  /// Used for change detection.
  _MapChangeRecord<K, V> prev;

  /// Used for iterating changes.
  _MapChangeRecord<K, V> nextChange;

  _MapChangeRecord(this.key, this.value);
}
