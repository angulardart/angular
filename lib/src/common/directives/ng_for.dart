import "package:angular2/core.dart"
    show
        DoCheck,
        Directive,
        ChangeDetectorRef,
        IterableDiffer,
        IterableDiffers,
        ViewContainerRef,
        ViewRef,
        TemplateRef,
        EmbeddedViewRef,
        TrackByFn;

import "../../core/change_detection/differs/default_iterable_differ.dart"
    show DefaultIterableDiffer, CollectionChangeRecord;
import "../../facade/exceptions.dart" show BaseException;

/// The `NgFor` directive instantiates a template once per item from an
/// iterable. The context for each instantiated template inherits from the outer
/// context with the given loop variable set to the current item from the
/// iterable.
///
/// ### Local Variables
///
/// `NgFor` provides several exported values that can be aliased to local
/// variables:
///
/// * `index` will be set to the current loop iteration for each template
/// context.
/// * `first` will be set to a boolean value indicating whether the item is the
/// first one in the
///   iteration.
/// * `last` will be set to a boolean value indicating whether the item is the
/// last one in the
///   iteration.
/// * `even` will be set to a boolean value indicating whether this item has an
/// even index.
/// * `odd` will be set to a boolean value indicating whether this item has an
/// odd index.
///
/// ### Change Propagation
///
/// When the contents of the iterator changes, `NgFor` makes the corresponding
/// changes to the DOM:
///
/// * When an item is added, a new instance of the template is added to the DOM.
/// * When an item is removed, its template instance is removed from the DOM.
/// * When items are reordered, their respective templates are reordered in the
/// DOM.
/// * Otherwise, the DOM element for that item will remain the same.
///
/// Angular uses object identity to track insertions and deletions within the
/// iterator and reproduce those changes in the DOM. This has important
/// implications for animations and any stateful controls
/// (such as `<input>` elements which accept user input) that are present.
/// Inserted rows can be animated in, deleted rows can be animated out, and
/// unchanged rows retain any unsaved state such as user input.
///
/// It is possible for the identities of elements in the iterator to change
/// while the data does not. This can happen, for example, if the iterator
/// produced from an RPC to the server, and that RPC is re-run. Even if the data
/// hasn't changed, the second response will produce objects with different
/// identities, and Angular will tear down the entire DOM and rebuild it (as if
/// all old elements were deleted and all new elements inserted). This is an
/// expensive operation and should be avoided if possible.
///
/// ### Examples
///
/// {@example docs/template-syntax/lib/app_component.html region=NgFor-1}
///
/// {@example docs/template-syntax/lib/app_component.html region=NgFor-3}
///
/// {@example docs/template-syntax/lib/app_component.html region=Template-3}
///
/// {@example docs/template-syntax/lib/app_component.html region=Template-4}
///
/// See the [Template Syntax section on `ngFor`][guide] for details.
///
/// [guide]: docs/guide/template-syntax.html#ngFor
@Directive(
    selector: "[ngFor][ngForOf]",
    inputs: const ["ngForTrackBy", "ngForOf", "ngForTemplate"])
class NgFor implements DoCheck {
  ViewContainerRef _viewContainer;
  TemplateRef _templateRef;
  IterableDiffers _iterableDiffers;
  ChangeDetectorRef _cdr;
  dynamic _ngForOf;
  TrackByFn _ngForTrackBy;
  IterableDiffer _differ;
  NgFor(
      this._viewContainer, this._templateRef, this._iterableDiffers, this._cdr);
  set ngForOf(dynamic value) {
    this._ngForOf = value;
    if (_differ == null && value != null) {
      try {
        this._differ = this
            ._iterableDiffers
            .find(value)
            .create(this._cdr, this._ngForTrackBy);
      } catch (_) {
        assert(() {
          throw new BaseException('Cannot find a differ supporting object'
              ' \'${ value}\' of type'
              ' \'${ value?.runtimeType }\''
              '. NgFor only supports binding to Iterables '
              'such as Arrays.');
        });
        rethrow;
      }
    }
  }

  set ngForTemplate(TemplateRef value) {
    if (value != null) {
      this._templateRef = value;
    }
  }

  set ngForTrackBy(TrackByFn value) {
    this._ngForTrackBy = value;
  }

  @override
  void ngDoCheck() {
    if (_differ != null) {
      var changes = this._differ.diff(this._ngForOf);
      if (changes != null) this._applyChanges(changes);
    }
  }

  void _applyChanges(DefaultIterableDiffer changes) {
    // TODO(rado): check if change detection can produce a change record that is
    // easier to consume than current.

    final insertTuples = <RecordViewTuple>[];
    changes.forEachOperation((CollectionChangeRecord item,
        int adjustedPreviousIndex, int currentIndex) {
      if (item.previousIndex == null) {
        var view =
            this._viewContainer.insertEmbeddedView(_templateRef, currentIndex);
        var tuple = new RecordViewTuple(item, view);
        insertTuples.add(tuple);
      } else if (currentIndex == null) {
        _viewContainer.remove(adjustedPreviousIndex);
      } else {
        ViewRef view = this._viewContainer.get(adjustedPreviousIndex);
        this._viewContainer.move(view, currentIndex);
        RecordViewTuple tuple = new RecordViewTuple(item, view);
        insertTuples.add(tuple);
      }
    });

    for (var i = 0; i < insertTuples.length; i++) {
      this._perViewChange(insertTuples[i].view, insertTuples[i].record);
    }
    for (var i = 0, ilen = this._viewContainer.length; i < ilen; i++) {
      var viewRef = _viewContainer.get(i);
      viewRef.setLocal("first", identical(i, 0));
      viewRef.setLocal("last", identical(i, ilen - 1));
      viewRef.setLocal("index", i);
      viewRef.setLocal("count", ilen);
    }
    changes.forEachIdentityChange((record) {
      var viewRef = _viewContainer.get(record.currentIndex);
      viewRef.setLocal("\$implicit", record.item);
    });
  }

  void _perViewChange(EmbeddedViewRef view, CollectionChangeRecord record) {
    view.setLocal("\$implicit", record.item);
    view.setLocal("even", (record.currentIndex % 2 == 0));
    view.setLocal("odd", (record.currentIndex % 2 == 1));
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
