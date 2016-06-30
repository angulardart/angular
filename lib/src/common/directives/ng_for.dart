library angular2.src.common.directives.ng_for;

import "package:angular2/core.dart"
    show
        DoCheck,
        Directive,
        ChangeDetectorRef,
        IterableDiffer,
        IterableDiffers,
        ViewContainerRef,
        TemplateRef,
        EmbeddedViewRef,
        TrackByFn;
import "package:angular2/src/facade/lang.dart"
    show isPresent, isBlank, stringify, getTypeNameForDebugging;
import "../../core/change_detection/differs/default_iterable_differ.dart"
    show DefaultIterableDiffer, CollectionChangeRecord;
import "../../facade/exceptions.dart" show BaseException;

/**
 * The `NgFor` directive instantiates a template once per item from an iterable. The context for
 * each instantiated template inherits from the outer context with the given loop variable set
 * to the current item from the iterable.
 *
 * ### Local Variables
 *
 * `NgFor` provides several exported values that can be aliased to local variables:
 *
 * * `index` will be set to the current loop iteration for each template context.
 * * `first` will be set to a boolean value indicating whether the item is the first one in the
 *   iteration.
 * * `last` will be set to a boolean value indicating whether the item is the last one in the
 *   iteration.
 * * `even` will be set to a boolean value indicating whether this item has an even index.
 * * `odd` will be set to a boolean value indicating whether this item has an odd index.
 *
 * ### Change Propagation
 *
 * When the contents of the iterator changes, `NgFor` makes the corresponding changes to the DOM:
 *
 * * When an item is added, a new instance of the template is added to the DOM.
 * * When an item is removed, its template instance is removed from the DOM.
 * * When items are reordered, their respective templates are reordered in the DOM.
 * * Otherwise, the DOM element for that item will remain the same.
 *
 * Angular uses object identity to track insertions and deletions within the iterator and reproduce
 * those changes in the DOM. This has important implications for animations and any stateful
 * controls
 * (such as `<input>` elements which accept user input) that are present. Inserted rows can be
 * animated in, deleted rows can be animated out, and unchanged rows retain any unsaved state such
 * as user input.
 *
 * It is possible for the identities of elements in the iterator to change while the data does not.
 * This can happen, for example, if the iterator produced from an RPC to the server, and that
 * RPC is re-run. Even if the data hasn't changed, the second response will produce objects with
 * different identities, and Angular will tear down the entire DOM and rebuild it (as if all old
 * elements were deleted and all new elements inserted). This is an expensive operation and should
 * be avoided if possible.
 *
 * ### Syntax
 *
 * - `<li *ngFor="let item of items; #i = index">...</li>`
 * - `<li template="ngFor #item of items; #i = index">...</li>`
 * - `<template ngFor #item [ngForOf]="items" #i="index"><li>...</li></template>`
 *
 * ### Example
 *
 * See a [live demo](http://plnkr.co/edit/KVuXxDp0qinGDyo307QW?p=preview) for a more detailed
 * example.
 */
@Directive(
    selector: "[ngFor][ngForOf]",
    inputs: const ["ngForTrackBy", "ngForOf", "ngForTemplate"])
class NgFor implements DoCheck {
  ViewContainerRef _viewContainer;
  TemplateRef _templateRef;
  IterableDiffers _iterableDiffers;
  ChangeDetectorRef _cdr;
  /** @internal */
  dynamic _ngForOf;
  /** @internal */
  TrackByFn _ngForTrackBy;
  IterableDiffer _differ;
  NgFor(this._viewContainer, this._templateRef, this._iterableDiffers,
      this._cdr) {}
  set ngForOf(dynamic value) {
    this._ngForOf = value;
    if (isBlank(this._differ) && isPresent(value)) {
      try {
        this._differ = this
            ._iterableDiffers
            .find(value)
            .create(this._cdr, this._ngForTrackBy);
      } catch (e, e_stack) {
        throw new BaseException(
            '''Cannot find a differ supporting object \'${ value}\' of type \'${ getTypeNameForDebugging ( value )}\'. NgFor only supports binding to Iterables such as Arrays.''');
      }
    }
  }

  set ngForTemplate(TemplateRef value) {
    if (isPresent(value)) {
      this._templateRef = value;
    }
  }

  set ngForTrackBy(TrackByFn value) {
    this._ngForTrackBy = value;
  }

  ngDoCheck() {
    if (isPresent(this._differ)) {
      var changes = this._differ.diff(this._ngForOf);
      if (isPresent(changes)) this._applyChanges(changes);
    }
  }

  _applyChanges(DefaultIterableDiffer changes) {
    // TODO(rado): check if change detection can produce a change record that is

    // easier to consume than current.
    List<RecordViewTuple> recordViewTuples = [];
    changes.forEachRemovedItem((CollectionChangeRecord removedRecord) =>
        recordViewTuples.add(new RecordViewTuple(removedRecord, null)));
    changes.forEachMovedItem((CollectionChangeRecord movedRecord) =>
        recordViewTuples.add(new RecordViewTuple(movedRecord, null)));
    var insertTuples = this._bulkRemove(recordViewTuples);
    changes.forEachAddedItem((CollectionChangeRecord addedRecord) =>
        insertTuples.add(new RecordViewTuple(addedRecord, null)));
    this._bulkInsert(insertTuples);
    for (var i = 0; i < insertTuples.length; i++) {
      this._perViewChange(insertTuples[i].view, insertTuples[i].record);
    }
    for (var i = 0, ilen = this._viewContainer.length; i < ilen; i++) {
      var viewRef = (this._viewContainer.get(i) as EmbeddedViewRef);
      viewRef.setLocal("first", identical(i, 0));
      viewRef.setLocal("last", identical(i, ilen - 1));
    }
    changes.forEachIdentityChange((record) {
      var viewRef =
          (this._viewContainer.get(record.currentIndex) as EmbeddedViewRef);
      viewRef.setLocal("\$implicit", record.item);
    });
  }

  _perViewChange(EmbeddedViewRef view, CollectionChangeRecord record) {
    view.setLocal("\$implicit", record.item);
    view.setLocal("index", record.currentIndex);
    view.setLocal("even", (record.currentIndex % 2 == 0));
    view.setLocal("odd", (record.currentIndex % 2 == 1));
  }

  List<RecordViewTuple> _bulkRemove(List<RecordViewTuple> tuples) {
    tuples.sort((RecordViewTuple a, RecordViewTuple b) =>
        a.record.previousIndex - b.record.previousIndex);
    List<RecordViewTuple> movedTuples = [];
    for (var i = tuples.length - 1; i >= 0; i--) {
      var tuple = tuples[i];
      // separate moved views from removed views.
      if (isPresent(tuple.record.currentIndex)) {
        tuple.view = (this._viewContainer.detach(tuple.record.previousIndex)
            as EmbeddedViewRef);
        movedTuples.add(tuple);
      } else {
        this._viewContainer.remove(tuple.record.previousIndex);
      }
    }
    return movedTuples;
  }

  List<RecordViewTuple> _bulkInsert(List<RecordViewTuple> tuples) {
    tuples.sort((a, b) => a.record.currentIndex - b.record.currentIndex);
    for (var i = 0; i < tuples.length; i++) {
      var tuple = tuples[i];
      if (isPresent(tuple.view)) {
        this._viewContainer.insert(tuple.view, tuple.record.currentIndex);
      } else {
        tuple.view = this
            ._viewContainer
            .createEmbeddedView(this._templateRef, tuple.record.currentIndex);
      }
    }
    return tuples;
  }
}

class RecordViewTuple {
  EmbeddedViewRef view;
  dynamic record;
  RecordViewTuple(dynamic record, EmbeddedViewRef view) {
    this.record = record;
    this.view = view;
  }
}
