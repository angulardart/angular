import 'dart:async';

import 'package:angular2/core.dart';
import 'package:angular2/src/core/change_detection/differs/default_iterable_differ.dart';
import 'package:observable/observable.dart' show ObservableList;

@Deprecated('No longer part of Angular. Copy into your project if needed')
class ObservableListDiff extends DefaultIterableDiffer {
  ChangeDetectorRef _ref;
  ObservableListDiff(this._ref);

  bool _updated = true;
  ObservableList _collection;
  StreamSubscription _subscription;

  @override
  void onDestroy() {
    if (this._subscription != null) {
      this._subscription.cancel();
      this._subscription = null;
      this._collection = null;
    }
  }

  @override
  DefaultIterableDiffer diff(Iterable iterable) {
    assert(iterable is ObservableList);
    ObservableList collection = iterable;

    // A new collection instance is passed in.
    // - We need to set up a listener.
    // - We need to diff collection.
    if (!identical(_collection, collection)) {
      _collection = collection;

      if (_subscription != null) _subscription.cancel();
      _subscription = collection.changes.listen((_) {
        _updated = true;
        _ref.markForCheck();
      });
      _updated = false;
      return super.diff(collection);

      // An update has been registered since the last change detection check.
      // - We reset the flag.
      // - We diff the collection.
    } else if (_updated) {
      _updated = false;
      return super.diff(collection);

      // No updates has been registered.
    } else {
      return null;
    }
  }
}

@Deprecated('No longer part of Angular. Copy into your project if needed')
class ObservableListDiffFactory implements IterableDifferFactory {
  const ObservableListDiffFactory();
  @override
  bool supports(obj) => obj is ObservableList;
  @override
  IterableDiffer create(ChangeDetectorRef cdRef, [Function trackByFn]) {
    return new ObservableListDiff(cdRef);
  }
}
