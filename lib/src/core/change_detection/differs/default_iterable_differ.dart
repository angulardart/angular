import "package:angular2/src/facade/collection.dart"
    show isListLikeIterable, iterateListLike;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, stringify, getMapKey, looseIdentical, isArray;

import "../change_detector_ref.dart" show ChangeDetectorRef;
import "../differs/iterable_differs.dart"
    show IterableDiffer, IterableDifferFactory, TrackByFn;

class DefaultIterableDifferFactory implements IterableDifferFactory {
  bool supports(Object obj) {
    return isListLikeIterable(obj);
  }

  DefaultIterableDiffer create(ChangeDetectorRef cdRef, [TrackByFn trackByFn]) {
    return new DefaultIterableDiffer(trackByFn);
  }

  const DefaultIterableDifferFactory();
}

var trackByIdentity = (num index, dynamic item) => item;

class DefaultIterableDiffer implements IterableDiffer<Iterable> {
  TrackByFn _trackByFn;
  num _length = null;
  var _collection = null;
  // Keeps track of the used records at any point in time (during & across `_check()` calls)
  _DuplicateMap _linkedRecords = null;
  // Keeps track of the removed records at any point in time during `_check()` calls.
  _DuplicateMap _unlinkedRecords = null;
  CollectionChangeRecord _previousItHead = null;
  CollectionChangeRecord _itHead = null;
  CollectionChangeRecord _itTail = null;
  CollectionChangeRecord _additionsHead = null;
  CollectionChangeRecord _additionsTail = null;
  CollectionChangeRecord _movesHead = null;
  CollectionChangeRecord _movesTail = null;
  CollectionChangeRecord _removalsHead = null;
  CollectionChangeRecord _removalsTail = null;
  // Keeps track of records where custom track by is the same, but item identity has changed
  CollectionChangeRecord _identityChangesHead = null;
  CollectionChangeRecord _identityChangesTail = null;
  DefaultIterableDiffer([this._trackByFn]) {
    this._trackByFn =
        isPresent(this._trackByFn) ? this._trackByFn : trackByIdentity;
  }
  get collection {
    return this._collection;
  }

  num get length {
    return this._length;
  }

  forEachItem(Function fn) {
    CollectionChangeRecord record;
    for (record = this._itHead;
        !identical(record, null);
        record = record._next) {
      fn(record);
    }
  }

  forEachPreviousItem(Function fn) {
    CollectionChangeRecord record;
    for (record = this._previousItHead;
        !identical(record, null);
        record = record._nextPrevious) {
      fn(record);
    }
  }

  forEachAddedItem(Function fn) {
    CollectionChangeRecord record;
    for (record = this._additionsHead;
        !identical(record, null);
        record = record._nextAdded) {
      fn(record);
    }
  }

  forEachMovedItem(Function fn) {
    CollectionChangeRecord record;
    for (record = this._movesHead;
        !identical(record, null);
        record = record._nextMoved) {
      fn(record);
    }
  }

  forEachRemovedItem(Function fn) {
    CollectionChangeRecord record;
    for (record = this._removalsHead;
        !identical(record, null);
        record = record._nextRemoved) {
      fn(record);
    }
  }

  forEachIdentityChange(Function fn) {
    CollectionChangeRecord record;
    for (record = this._identityChangesHead;
        !identical(record, null);
        record = record._nextIdentityChange) {
      fn(record);
    }
  }

  DefaultIterableDiffer diff(Iterable collection) {
    if (isBlank(collection)) collection = [];
    if (!isListLikeIterable(collection)) {
      throw new BaseException('''Error trying to diff \'${ collection}\'''');
    }
    if (this.check(collection)) {
      return this;
    } else {
      return null;
    }
  }

  onDestroy() {}
  // todo(vicb): optim for UnmodifiableListView (frozen arrays)
  bool check(dynamic collection) {
    this._reset();
    CollectionChangeRecord record = this._itHead;
    bool mayBeDirty = false;
    num index;
    var item;
    var itemTrackBy;
    if (isArray(collection)) {
      var list = collection;
      this._length = collection.length;
      for (index = 0; index < this._length; index++) {
        item = list[index];
        itemTrackBy = this._trackByFn(index, item);
        if (identical(record, null) ||
            !looseIdentical(record.trackById, itemTrackBy)) {
          record = this._mismatch(record, item, itemTrackBy, index);
          mayBeDirty = true;
        } else {
          if (mayBeDirty) {
            // TODO(misko): can we limit this to duplicates only?
            record = this._verifyReinsertion(record, item, itemTrackBy, index);
          }
          if (!looseIdentical(record.item, item))
            this._addIdentityChange(record, item);
        }
        record = record._next;
      }
    } else {
      index = 0;
      iterateListLike(collection, (item) {
        itemTrackBy = this._trackByFn(index, item);
        if (identical(record, null) ||
            !looseIdentical(record.trackById, itemTrackBy)) {
          record = this._mismatch(record, item, itemTrackBy, index);
          mayBeDirty = true;
        } else {
          if (mayBeDirty) {
            // TODO(misko): can we limit this to duplicates only?
            record = this._verifyReinsertion(record, item, itemTrackBy, index);
          }
          if (!looseIdentical(record.item, item))
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

  /* CollectionChanges is considered dirty if it has any additions, moves, removals, or identity
   * changes.
   */
  bool get isDirty {
    return !identical(this._additionsHead, null) ||
        !identical(this._movesHead, null) ||
        !identical(this._removalsHead, null) ||
        !identical(this._identityChangesHead, null);
  }

  /**
   * Reset the state of the change objects to show no changes. This means set previousKey to
   * currentKey, and clear all of the queues (additions, moves, removals).
   * Set the previousIndexes of moved and added items to their currentIndexes
   * Reset the list of additions, moves and removals
   *
   * @internal
   */
  _reset() {
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

  /**
   * This is the core function which handles differences between collections.
   *
   * - `record` is the record which we saw at this position last time. If null then it is a new
   *   item.
   * - `item` is the current item in the collection
   * - `index` is the position of the item in the collection
   *
   * @internal
   */
  CollectionChangeRecord _mismatch(CollectionChangeRecord record, dynamic item,
      dynamic itemTrackBy, num index) {
    // The previous record after which we will append the current one.
    CollectionChangeRecord previousRecord;
    if (identical(record, null)) {
      previousRecord = this._itTail;
    } else {
      previousRecord = record._prev;
      // Remove the record from the collection since we know it does not match the item.
      this._remove(record);
    }
    // Attempt to see if we have seen the item before.
    record = identical(this._linkedRecords, null)
        ? null
        : this._linkedRecords.get(itemTrackBy, index);
    if (!identical(record, null)) {
      // We have seen this before, we need to move it forward in the collection.

      // But first we need to check if identity changed, so we can update in view if necessary
      if (!looseIdentical(record.item, item))
        this._addIdentityChange(record, item);
      this._moveAfter(record, previousRecord, index);
    } else {
      // Never seen it, check evicted list.
      record = identical(this._unlinkedRecords, null)
          ? null
          : this._unlinkedRecords.get(itemTrackBy);
      if (!identical(record, null)) {
        // It is an item which we have evicted earlier: reinsert it back into the list.

        // But first we need to check if identity changed, so we can update in view if necessary
        if (!looseIdentical(record.item, item))
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

  /**
   * This check is only needed if an array contains duplicates. (Short circuit of nothing dirty)
   *
   * Use case: `[a, a]` => `[b, a, a]`
   *
   * If we did not have this check then the insertion of `b` would:
   *   1) evict first `a`
   *   2) insert `b` at `0` index.
   *   3) leave `a` at index `1` as is. <-- this is wrong!
   *   3) reinsert `a` at index 2. <-- this is wrong!
   *
   * The correct behavior is:
   *   1) evict first `a`
   *   2) insert `b` at `0` index.
   *   3) reinsert `a` at index 1.
   *   3) move `a` at from `1` to `2`.
   *
   *
   * Double check that we have not evicted a duplicate item. We need to check if the item type may
   * have already been removed:
   * The insertion of b will evict the first 'a'. If we don't reinsert it now it will be reinserted
   * at the end. Which will show up as the two 'a's switching position. This is incorrect, since a
   * better way to think of it is as insert of 'b' rather then switch 'a' with 'b' and then add 'a'
   * at the end.
   *
   * @internal
   */
  CollectionChangeRecord _verifyReinsertion(CollectionChangeRecord record,
      dynamic item, dynamic itemTrackBy, num index) {
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

  /**
   * Get rid of any excess [CollectionChangeRecord]s from the previous collection
   *
   * - `record` The first excess [CollectionChangeRecord].
   *
   * @internal
   */
  _truncate(CollectionChangeRecord record) {
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

  /** @internal */
  CollectionChangeRecord _reinsertAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, num index) {
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

  /** @internal */
  CollectionChangeRecord _moveAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, num index) {
    this._unlink(record);
    this._insertAfter(record, prevRecord, index);
    this._addToMoves(record, index);
    return record;
  }

  /** @internal */
  CollectionChangeRecord _addAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, num index) {
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

  /** @internal */
  CollectionChangeRecord _insertAfter(CollectionChangeRecord record,
      CollectionChangeRecord prevRecord, num index) {
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
    if (identical(this._linkedRecords, null)) {
      this._linkedRecords = new _DuplicateMap();
    }
    this._linkedRecords.put(record);
    record.currentIndex = index;
    return record;
  }

  /** @internal */
  CollectionChangeRecord _remove(CollectionChangeRecord record) {
    return this._addToRemovals(this._unlink(record));
  }

  /** @internal */
  CollectionChangeRecord _unlink(CollectionChangeRecord record) {
    if (!identical(this._linkedRecords, null)) {
      this._linkedRecords.remove(record);
    }
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

  /** @internal */
  CollectionChangeRecord _addToMoves(
      CollectionChangeRecord record, num toIndex) {
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

  /** @internal */
  CollectionChangeRecord _addToRemovals(CollectionChangeRecord record) {
    if (identical(this._unlinkedRecords, null)) {
      this._unlinkedRecords = new _DuplicateMap();
    }
    this._unlinkedRecords.put(record);
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

  /** @internal */
  _addIdentityChange(CollectionChangeRecord record, dynamic item) {
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
    this.forEachItem((record) => list.add(record));
    var previous = [];
    this.forEachPreviousItem((record) => previous.add(record));
    var additions = [];
    this.forEachAddedItem((record) => additions.add(record));
    var moves = [];
    this.forEachMovedItem((record) => moves.add(record));
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
  num currentIndex = null;
  num previousIndex = null;
  /** @internal */
  CollectionChangeRecord _nextPrevious = null;
  /** @internal */
  CollectionChangeRecord _prev = null;
  /** @internal */
  CollectionChangeRecord _next = null;
  /** @internal */
  CollectionChangeRecord _prevDup = null;
  /** @internal */
  CollectionChangeRecord _nextDup = null;
  /** @internal */
  CollectionChangeRecord _prevRemoved = null;
  /** @internal */
  CollectionChangeRecord _nextRemoved = null;
  /** @internal */
  CollectionChangeRecord _nextAdded = null;
  /** @internal */
  CollectionChangeRecord _nextMoved = null;
  /** @internal */
  CollectionChangeRecord _nextIdentityChange = null;
  CollectionChangeRecord(this.item, this.trackById) {}
  String toString() {
    return identical(this.previousIndex, this.currentIndex)
        ? stringify(this.item)
        : stringify(this.item) +
            "[" +
            stringify(this.previousIndex) +
            "->" +
            stringify(this.currentIndex) +
            "]";
  }
}

// A linked list of CollectionChangeRecords with the same CollectionChangeRecord.item
class _DuplicateItemRecordList {
  /** @internal */
  CollectionChangeRecord _head = null;
  /** @internal */
  CollectionChangeRecord _tail = null;
  /**
   * Append the record to the list of duplicates.
   *
   * Note: by design all records in the list of duplicates hold the same value in record.item.
   */
  void add(CollectionChangeRecord record) {
    if (identical(this._head, null)) {
      this._head = this._tail = record;
      record._nextDup = null;
      record._prevDup = null;
    } else {
      // todo(vicb)

      // assert(record.item ==  _head.item ||

      //       record.item is num && record.item.isNaN && _head.item is num && _head.item.isNaN);
      this._tail._nextDup = record;
      record._prevDup = this._tail;
      record._nextDup = null;
      this._tail = record;
    }
  }
  // Returns a CollectionChangeRecord having CollectionChangeRecord.trackById == trackById and

  // CollectionChangeRecord.currentIndex >= afterIndex
  CollectionChangeRecord get(dynamic trackById, num afterIndex) {
    CollectionChangeRecord record;
    for (record = this._head;
        !identical(record, null);
        record = record._nextDup) {
      if ((identical(afterIndex, null) || afterIndex < record.currentIndex) &&
          looseIdentical(record.trackById, trackById)) {
        return record;
      }
    }
    return null;
  }

  /**
   * Remove one [CollectionChangeRecord] from the list of duplicates.
   *
   * Returns whether the list of duplicates is empty.
   */
  bool remove(CollectionChangeRecord record) {
    // todo(vicb)

    // assert(() {

    //  // verify that the record being removed is in the list.

    //  for (CollectionChangeRecord cursor = _head; cursor != null; cursor = cursor._nextDup) {

    //    if (identical(cursor, record)) return true;

    //  }

    //  return false;

    //});
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
  var map = new Map<dynamic, _DuplicateItemRecordList>();
  put(CollectionChangeRecord record) {
    // todo(vicb) handle corner cases
    var key = getMapKey(record.trackById);
    var duplicates = this.map[key];
    if (!isPresent(duplicates)) {
      duplicates = new _DuplicateItemRecordList();
      this.map[key] = duplicates;
    }
    duplicates.add(record);
  }

  /**
   * Retrieve the `value` using key. Because the CollectionChangeRecord value may be one which we
   * have already iterated over, we use the afterIndex to pretend it is not there.
   *
   * Use case: `[a, b, c, a, a]` if we are at index `3` which is the second `a` then asking if we
   * have any more `a`s needs to return the last `a` not the first or second.
   */
  CollectionChangeRecord get(dynamic trackById, [num afterIndex = null]) {
    var key = getMapKey(trackById);
    var recordList = this.map[key];
    return isBlank(recordList) ? null : recordList.get(trackById, afterIndex);
  }

  /**
   * Removes a [CollectionChangeRecord] from the list of duplicates.
   *
   * The list of duplicates also is removed from the map if it gets empty.
   */
  CollectionChangeRecord remove(CollectionChangeRecord record) {
    var key = getMapKey(record.trackById);
    // todo(vicb)

    // assert(this.map.containsKey(key));
    _DuplicateItemRecordList recordList = this.map[key];
    // Remove the list of duplicates when it gets empty
    if (recordList.remove(record)) {
      (this.map.containsKey(key) && (this.map.remove(key) != null || true));
    }
    return record;
  }

  bool get isEmpty {
    return identical(this.map.length, 0);
  }

  clear() {
    this.map.clear();
  }

  String toString() {
    return "_DuplicateMap(" + stringify(this.map) + ")";
  }
}
