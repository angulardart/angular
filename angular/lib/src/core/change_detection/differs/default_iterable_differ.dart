import 'package:angular/src/facade/exceptions.dart' show BaseException;

typedef void DefaultIterableCallback(
  CollectionChangeRecord item,
  int previousIndex,
  int currentIndex,
);

typedef dynamic TrackByFn(int index, dynamic item);

var trackByIdentity = (int index, dynamic item) => item;

class DefaultIterableDiffer {
  final TrackByFn _trackByFn;
  int _length;
  Iterable _collection;
  // Keeps track of the used records at any point in time (during & across
  // `_check()` calls)
  _DuplicateMap _linkedRecords;
  // Keeps track of the removed records at any point in time during `_check()`
  // calls.
  _DuplicateMap _unlinkedRecords;
  CollectionChangeRecord _previousItHead;
  CollectionChangeRecord _itHead;
  CollectionChangeRecord _itTail;
  CollectionChangeRecord _additionsHead;
  CollectionChangeRecord _additionsTail;
  CollectionChangeRecord _movesHead;
  CollectionChangeRecord _movesTail;
  CollectionChangeRecord _removalsHead;
  CollectionChangeRecord _removalsTail;
  // Keeps track of records where custom track by is the same, but item identity
  // has changed
  CollectionChangeRecord _identityChangesHead;
  CollectionChangeRecord _identityChangesTail;

  // Detect DartVM to special case string identical.
  static const bool _useIdentity = identical(1.0, 1);

  DefaultIterableDiffer([TrackByFn trackByFn])
      : _trackByFn = trackByFn ?? trackByIdentity;

  DefaultIterableDiffer clone(TrackByFn trackByFn) {
    var differ = new DefaultIterableDiffer(trackByFn);
    return differ
      .._length = _length
      .._collection = _collection
      .._linkedRecords = _linkedRecords
      .._unlinkedRecords = _unlinkedRecords
      .._previousItHead = _previousItHead
      .._itHead = _itHead
      .._itTail = _itTail
      .._additionsHead = _additionsHead
      .._additionsTail = _additionsTail
      .._movesHead = _movesHead
      .._movesTail = _movesTail
      .._removalsHead = _removalsHead
      .._removalsTail = _removalsTail
      .._identityChangesHead = _identityChangesHead
      .._identityChangesTail = _identityChangesTail;
  }

  Iterable get collection => _collection;

  int get length => _length;

  void forEachOperation(DefaultIterableCallback fn) {
    var nextIt = _itHead;
    var nextRemove = _removalsHead;
    int addRemoveOffset = 0;
    int sizeDeficit;
    List<int> moveOffsets;

    while (nextIt != null || nextRemove != null) {
      // Figure out which is the next record to process
      // Order: remove, add, move
      dynamic record = nextRemove == null ||
              nextIt != null &&
                  nextIt.currentIndex <
                      _getPreviousIndex(
                          nextRemove, addRemoveOffset, moveOffsets)
          ? nextIt
          : nextRemove;

      int adjPreviousIndex =
          _getPreviousIndex(record, addRemoveOffset, moveOffsets);

      int currentIndex = record.currentIndex;

      // consume the item, adjust the addRemoveOffset and update
      // moveDistance if necessary
      if (identical(record, nextRemove)) {
        addRemoveOffset--;
        nextRemove = nextRemove._nextRemoved;
      } else {
        nextIt = nextIt._next;

        if (record.previousIndex == null) {
          addRemoveOffset++;
        } else {
          // INVARIANT:  currentIndex < previousIndex
          moveOffsets ??= <int>[];

          int localMovePreviousIndex = adjPreviousIndex - addRemoveOffset;
          int localCurrentIndex = currentIndex - addRemoveOffset;

          if (localMovePreviousIndex != localCurrentIndex) {
            for (int i = 0; i < localMovePreviousIndex; i++) {
              int offset;

              if (i < moveOffsets.length) {
                offset = moveOffsets[i];
              } else {
                if (moveOffsets.length > i) {
                  offset = moveOffsets[i] = 0;
                } else {
                  sizeDeficit = i - moveOffsets.length + 1;
                  for (int j = 0; j < sizeDeficit; j++) {
                    moveOffsets.add(null);
                  }
                  offset = moveOffsets[i] = 0;
                }
              }

              int index = offset + i;

              if (localCurrentIndex <= index &&
                  index < localMovePreviousIndex) {
                moveOffsets[i] = offset + 1;
              }
            }

            int previousIndex = record.previousIndex;
            sizeDeficit = previousIndex - moveOffsets.length + 1;
            for (int j = 0; j < sizeDeficit; j++) {
              moveOffsets.add(null);
            }
            moveOffsets[previousIndex] =
                localCurrentIndex - localMovePreviousIndex;
          }
        }
      }

      if (adjPreviousIndex != currentIndex) {
        fn(record, adjPreviousIndex, currentIndex);
      }
    }
  }

  void forEachAddedItem(void fn(CollectionChangeRecord record)) {
    for (var record = this._additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      fn(record);
    }
  }

  void forEachRemovedItem(void fn(CollectionChangeRecord record)) {
    for (var record = this._removalsHead;
        !identical(record, null);
        record = record._nextRemoved) {
      fn(record);
    }
  }

  void forEachIdentityChange(void fn(CollectionChangeRecord record)) {
    for (var record = this._identityChangesHead;
        !identical(record, null);
        record = record._nextIdentityChange) {
      fn(record);
    }
  }

  DefaultIterableDiffer diff(Iterable collection) {
    if (collection != null) {
      if (collection is! Iterable) {
        throw new BaseException("Error trying to diff '$collection'");
      }
    } else {
      collection = const [];
    }
    return this.check(collection) ? this : null;
  }

  void onDestroy() {}
  // todo(vicb): optim for UnmodifiableListView (frozen arrays)
  bool check(Iterable collection) {
    this._reset();
    CollectionChangeRecord record = this._itHead;
    bool mayBeDirty = false;
    int index;
    var item;
    var itemTrackBy;
    if (collection is List) {
      var list = collection;
      this._length = collection.length;
      for (index = 0; index < this._length; index++) {
        item = list[index];
        itemTrackBy = this._trackByFn(index, item);
        if (identical(record, null) ||
            !identical(record.trackById, itemTrackBy)) {
          record = this._mismatch(record, item, itemTrackBy, index);
          mayBeDirty = true;
        } else {
          if (mayBeDirty) {
            // TODO(misko): can we limit this to duplicates only?
            record = this._verifyReinsertion(record, item, itemTrackBy, index);
          }
          if (!identical(record.item, item))
            this._addIdentityChange(record, item);
        }
        record = record._next;
      }
    } else {
      index = 0;
      collection.forEach((item) {
        itemTrackBy = this._trackByFn(index, item);
        if (identical(record, null) ||
            !identical(record.trackById, itemTrackBy)) {
          record = this._mismatch(record, item, itemTrackBy, index);
          mayBeDirty = true;
        } else {
          if (mayBeDirty) {
            // TODO(misko): can we limit this to duplicates only?
            record = this._verifyReinsertion(record, item, itemTrackBy, index);
          }
          if (!identical(record.item, item))
            this._addIdentityChange(record, item);
        }
        record = record._next;
        index++;
      });
      this._length = index;
    }
    this._truncate(record);
    this._collection = collection;
    return this.isDirty;
  }

  // CollectionChanges is considered dirty if it has any additions, moves,
  // removals, or identity changes.
  bool get isDirty {
    return !identical(this._additionsHead, null) ||
        !identical(this._movesHead, null) ||
        !identical(this._removalsHead, null) ||
        !identical(this._identityChangesHead, null);
  }

  /// Reset the state of the change objects to show no changes. This means set
  /// previousKey to currentKey, and clear all of the queues (additions, moves,
  /// removals). Set the previousIndexes of moved and added items to their
  /// currentIndexes. Reset the list of additions, moves and removals
  ///
  /// @internal
  void _reset() {
    if (this.isDirty) {
      CollectionChangeRecord record;
      CollectionChangeRecord nextRecord;
      for (record = this._previousItHead = this._itHead;
          !identical(record, null);
          record = record._next) {
        record._nextPrevious = record._next;
      }
      for (record = this._additionsHead;
          !identical(record, null);
          record = record._nextAdded) {
        record.previousIndex = record.currentIndex;
      }
      this._additionsHead = this._additionsTail = null;
      for (record = this._movesHead;
          !identical(record, null);
          record = nextRecord) {
        record.previousIndex = record.currentIndex;
        nextRecord = record._nextMoved;
      }
      this._movesHead = this._movesTail = null;
      this._removalsHead = this._removalsTail = null;
      this._identityChangesHead = this._identityChangesTail = null;
    }
  }

  /// This is the core function which handles differences between collections.
  ///
  /// - `record` is the record which we saw at this position last time. If null
  ///   then it is a new item.
  /// - `item` is the current item in the collection
  /// - `index` is the position of the item in the collection
  ///
  /// @internal
  CollectionChangeRecord _mismatch(CollectionChangeRecord record, dynamic item,
      dynamic itemTrackBy, int index) {
    // The previous record after which we will append the current one.
    CollectionChangeRecord previousRecord;
    if (identical(record, null)) {
      previousRecord = this._itTail;
    } else {
      previousRecord = record._prev;
      // Remove the record from the collection since we know it does not match
      // the item.
      this._remove(record);
    }
    // Attempt to see if we have seen the item before.
    record = identical(this._linkedRecords, null)
        ? null
        : this._linkedRecords.get(itemTrackBy, index);
    if (!identical(record, null)) {
      // We have seen this before, we need to move it forward in the collection.
      // But first we need to check if identity changed, so we can update in
      // view if necessary.
      if (!identical(record.item, item)) this._addIdentityChange(record, item);
      this._moveAfter(record, previousRecord, index);
    } else {
      // Never seen it, check evicted list.
      record = identical(this._unlinkedRecords, null)
          ? null
          : this._unlinkedRecords.get(itemTrackBy);
      if (!identical(record, null)) {
        // It is an item which we have evicted earlier: reinsert it back into
        // the list. But first we need to check if identity changed, so we can
        // update in view if necessary
        if (!identical(record.item, item))
          this._addIdentityChange(record, item);
        this._reinsertAfter(record, previousRecord, index);
      } else {
        // It is a new item: add it.
        record = this._addAfter(new CollectionChangeRecord(item, itemTrackBy),
            previousRecord, index);
      }
    }
    return record;
  }

  /// This check is only needed if an array contains duplicates. (Short circuit
  /// of nothing dirty)
  ///
  /// Use case: `[a, a]` => `[b, a, a]`
  ///
  /// If we did not have this check then the insertion of `b` would:
  ///   1) evict first `a`
  ///   2) insert `b` at `0` index.
  ///   3) leave `a` at index `1` as is. <-- this is wrong!
  ///   3) reinsert `a` at index 2. <-- this is wrong!
  ///
  /// The correct behavior is:
  ///   1) evict first `a`
  ///   2) insert `b` at `0` index.
  ///   3) reinsert `a` at index 1.
  ///   3) move `a` at from `1` to `2`.
  ///
  ///
  /// Double check that we have not evicted a duplicate item. We need to check
  /// if the item type may have already been removed:
  ///
  /// The insertion of b will evict the first 'a'. If we don't reinsert it now
  /// it will be reinserted at the end. Which will show up as the two 'a's
  /// switching position. This is incorrect, since a better way to think of it
  /// is as insert of 'b' rather then switch 'a' with 'b' and then add 'a'
  /// at the end.
  ///
  /// @internal
  CollectionChangeRecord _verifyReinsertion(CollectionChangeRecord record,
      dynamic item, dynamic itemTrackBy, int index) {
    CollectionChangeRecord reinsertRecord =
        identical(this._unlinkedRecords, null)
            ? null
            : this._unlinkedRecords.get(itemTrackBy);
    if (!identical(reinsertRecord, null)) {
      record = this._reinsertAfter(reinsertRecord, record._prev, index);
    } else if (record.currentIndex != index) {
      record.currentIndex = index;
      this._addToMoves(record, index);
    }
    return record;
  }

  /// Get rid of any excess [CollectionChangeRecord]s from the previous
  /// collection.
  ///
  /// - `record` The first excess [CollectionChangeRecord].
  ///
  /// @internal
  void _truncate(CollectionChangeRecord record) {
    // Anything after that needs to be removed;
    while (!identical(record, null)) {
      CollectionChangeRecord nextRecord = record._next;
      this._addToRemovals(this._unlink(record));
      record = nextRecord;
    }
    if (!identical(this._unlinkedRecords, null)) {
      this._unlinkedRecords.clear();
    }
    if (!identical(this._additionsTail, null)) {
      this._additionsTail._nextAdded = null;
    }
    if (!identical(this._movesTail, null)) {
      this._movesTail._nextMoved = null;
    }
    if (!identical(this._itTail, null)) {
      this._itTail._next = null;
    }
    if (!identical(this._removalsTail, null)) {
      this._removalsTail._nextRemoved = null;
    }
    if (!identical(this._identityChangesTail, null)) {
      this._identityChangesTail._nextIdentityChange = null;
    }
  }

  CollectionChangeRecord _reinsertAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, int index) {
    if (!identical(this._unlinkedRecords, null)) {
      this._unlinkedRecords.remove(record);
    }
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
    this._insertAfter(record, prevRecord, index);
    this._addToMoves(record, index);
    return record;
  }

  CollectionChangeRecord _moveAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, int index) {
    this._unlink(record);
    this._insertAfter(record, prevRecord, index);
    this._addToMoves(record, index);
    return record;
  }

  CollectionChangeRecord _addAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, int index) {
    this._insertAfter(record, prevRecord, index);
    if (identical(this._additionsTail, null)) {
      // todo(vicb)

      // assert(this._additionsHead === null);
      this._additionsTail = this._additionsHead = record;
    } else {
      // todo(vicb)

      // assert(_additionsTail._nextAdded === null);

      // assert(record._nextAdded === null);
      this._additionsTail = this._additionsTail._nextAdded = record;
    }
    return record;
  }

  CollectionChangeRecord _insertAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, int index) {
    // todo(vicb)

    // assert(record != prevRecord);

    // assert(record._next === null);

    // assert(record._prev === null);
    CollectionChangeRecord next =
        identical(prevRecord, null) ? this._itHead : prevRecord._next;
    // todo(vicb)

    // assert(next != record);

    // assert(prevRecord != record);
    record._next = next;
    record._prev = prevRecord;
    if (identical(next, null)) {
      this._itTail = record;
    } else {
      next._prev = record;
    }
    if (identical(prevRecord, null)) {
      this._itHead = record;
    } else {
      prevRecord._next = record;
    }
    _linkedRecords ??=
        _useIdentity ? new _DuplicateMap() : new _DuplicateMap.withHashcode();
    _linkedRecords.put(record);
    record.currentIndex = index;
    return record;
  }

  CollectionChangeRecord _remove(CollectionChangeRecord record) {
    return this._addToRemovals(this._unlink(record));
  }

  CollectionChangeRecord _unlink(CollectionChangeRecord record) {
    _linkedRecords?.remove(record);
    var prev = record._prev;
    var next = record._next;
    // todo(vicb)

    // assert((record._prev = null) === null);

    // assert((record._next = null) === null);
    if (identical(prev, null)) {
      this._itHead = next;
    } else {
      prev._next = next;
    }
    if (identical(next, null)) {
      this._itTail = prev;
    } else {
      next._prev = prev;
    }
    return record;
  }

  CollectionChangeRecord _addToMoves(
      CollectionChangeRecord record, int toIndex) {
    // todo(vicb)

    // assert(record._nextMoved === null);
    if (identical(record.previousIndex, toIndex)) {
      return record;
    }
    if (identical(this._movesTail, null)) {
      // todo(vicb)

      // assert(_movesHead === null);
      this._movesTail = this._movesHead = record;
    } else {
      // todo(vicb)

      // assert(_movesTail._nextMoved === null);
      this._movesTail = this._movesTail._nextMoved = record;
    }
    return record;
  }

  CollectionChangeRecord _addToRemovals(CollectionChangeRecord record) {
    _unlinkedRecords ??=
        _useIdentity ? new _DuplicateMap() : new _DuplicateMap.withHashcode();
    _unlinkedRecords.put(record);
    record.currentIndex = null;
    record._nextRemoved = null;
    if (identical(this._removalsTail, null)) {
      // todo(vicb)

      // assert(_removalsHead === null);
      this._removalsTail = this._removalsHead = record;
      record._prevRemoved = null;
    } else {
      // todo(vicb)

      // assert(_removalsTail._nextRemoved === null);

      // assert(record._nextRemoved === null);
      record._prevRemoved = this._removalsTail;
      this._removalsTail = this._removalsTail._nextRemoved = record;
    }
    return record;
  }

  CollectionChangeRecord _addIdentityChange(
      CollectionChangeRecord record, dynamic item) {
    record.item = item;
    if (identical(this._identityChangesTail, null)) {
      this._identityChangesTail = this._identityChangesHead = record;
    } else {
      this._identityChangesTail =
          this._identityChangesTail._nextIdentityChange = record;
    }
    return record;
  }

  String toString() {
    var list = [];
    for (var record = this._itHead;
        !identical(record, null);
        record = record._next) {
      list.add(record);
    }
    var previous = [];
    for (var record = this._previousItHead;
        !identical(record, null);
        record = record._nextPrevious) {
      previous.add(record);
    }
    var additions = [];
    this.forEachAddedItem((record) => additions.add(record));
    var moves = [];
    for (var record = this._movesHead;
        !identical(record, null);
        record = record._nextMoved) {
      moves.add(record);
    }
    var removals = [];
    this.forEachRemovedItem((record) => removals.add(record));
    var identityChanges = [];
    this.forEachIdentityChange((record) => identityChanges.add(record));
    return "collection: " +
        list.join(", ") +
        "\n" +
        "previous: " +
        previous.join(", ") +
        "\n" +
        "additions: " +
        additions.join(", ") +
        "\n" +
        "moves: " +
        moves.join(", ") +
        "\n" +
        "removals: " +
        removals.join(", ") +
        "\n" +
        "identityChanges: " +
        identityChanges.join(", ") +
        "\n";
  }
}

class CollectionChangeRecord {
  dynamic item;
  dynamic trackById;
  int currentIndex;
  int previousIndex;

  CollectionChangeRecord _nextPrevious;

  CollectionChangeRecord _prev;

  CollectionChangeRecord _next;

  CollectionChangeRecord _prevDup;

  CollectionChangeRecord _nextDup;

  CollectionChangeRecord _prevRemoved;

  CollectionChangeRecord _nextRemoved;

  CollectionChangeRecord _nextAdded;

  CollectionChangeRecord _nextMoved;

  CollectionChangeRecord _nextIdentityChange;
  CollectionChangeRecord(this.item, this.trackById);

  String toString() {
    return identical(previousIndex, currentIndex)
        ? item.toString()
        : '$item[$previousIndex->$currentIndex]';
  }
}

// A linked list of CollectionChangeRecords with the same
// CollectionChangeRecord.item
class _DuplicateItemRecordList {
  CollectionChangeRecord _head;

  CollectionChangeRecord _tail;

  /// Append the record to the list of duplicates.
  ///
  /// Note: by design all records in the list of duplicates hold the same value
  /// in record.item.
  void add(CollectionChangeRecord record) {
    if (identical(this._head, null)) {
      this._head = this._tail = record;
      record._nextDup = null;
      record._prevDup = null;
    } else {
      this._tail._nextDup = record;
      record._prevDup = this._tail;
      record._nextDup = null;
      this._tail = record;
    }
  }

  // Returns a CollectionChangeRecord having CollectionChangeRecord.trackById
  // == trackById and CollectionChangeRecord.currentIndex >= afterIndex
  CollectionChangeRecord get(dynamic trackById, int afterIndex) {
    CollectionChangeRecord record;
    for (record = this._head;
        !identical(record, null);
        record = record._nextDup) {
      if ((identical(afterIndex, null) || afterIndex < record.currentIndex) &&
          identical(record.trackById, trackById)) {
        return record;
      }
    }
    return null;
  }

  /// Remove one [CollectionChangeRecord] from the list of duplicates.
  ///
  /// Returns whether the list of duplicates is empty.
  bool remove(CollectionChangeRecord record) {
    CollectionChangeRecord prev = record._prevDup;
    CollectionChangeRecord next = record._nextDup;
    if (identical(prev, null)) {
      this._head = next;
    } else {
      prev._nextDup = next;
    }
    if (identical(next, null)) {
      this._tail = prev;
    } else {
      next._prevDup = prev;
    }
    return identical(this._head, null);
  }
}

class _DuplicateMap {
  Map _map;
  _DuplicateMap()
      : _map = new Map<dynamic, _DuplicateItemRecordList>.identity();
  _DuplicateMap.withHashcode()
      : _map = new Map<dynamic, _DuplicateItemRecordList>();
  void put(CollectionChangeRecord record) {
    // todo(vicb) handle corner cases
    var key = record.trackById;
    var duplicates = this._map[key];
    if (duplicates == null) {
      duplicates = new _DuplicateItemRecordList();
      this._map[key] = duplicates;
    }
    duplicates.add(record);
  }

  /// Retrieve the `value` using key. Because the CollectionChangeRecord value
  /// may be one which we have already iterated over, we use the afterIndex to
  /// pretend it is not there.
  ///
  /// Use case: `[a, b, c, a, a]` if we are at index `3` which is the second `a`
  /// then asking if we have any more `a`s needs to return the last `a` not the
  /// first or second.
  CollectionChangeRecord get(dynamic trackById, [int afterIndex]) {
    var recordList = this._map[trackById];
    return recordList == null ? null : recordList.get(trackById, afterIndex);
  }

  /// Removes a [CollectionChangeRecord] from the list of duplicates.
  ///
  /// The list of duplicates also is removed from the map if it gets empty.
  CollectionChangeRecord remove(CollectionChangeRecord record) {
    var key = record.trackById;
    // todo(vicb)
    // assert(this.map.containsKey(key));
    _DuplicateItemRecordList recordList = this._map[key];
    // Remove the list of duplicates when it gets empty
    if (recordList.remove(record)) {
      (this._map.containsKey(key) && (this._map.remove(key) != null || true));
    }
    return record;
  }

  bool get isEmpty {
    return identical(this._map.length, 0);
  }

  void clear() {
    this._map.clear();
  }

  String toString() {
    return "_DuplicateMap($_map)";
  }
}

int _getPreviousIndex(
    CollectionChangeRecord item, int addRemoveOffset, List<int> moveOffsets) {
  int previousIndex = item.previousIndex;

  if (previousIndex == null) return previousIndex;

  int moveOffset = 0;
  if (moveOffsets != null && previousIndex < moveOffsets.length) {
    moveOffset = moveOffsets[previousIndex];
  }

  return previousIndex + addRemoveOffset + moveOffset;
}
