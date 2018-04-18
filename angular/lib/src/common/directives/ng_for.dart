import 'package:angular/core.dart' show DoCheck, Directive, Input;

import '../../core/change_detection/differs/default_iterable_differ.dart'
    show DefaultIterableDiffer, CollectionChangeRecord, TrackByFn;
import '../../core/linker.dart'
    show ViewContainerRef, TemplateRef, EmbeddedViewRef;

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
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgFor-1)"?>
/// ```html
/// <div *ngFor="let hero of heroes">{{hero.name}}</div>
/// ```
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgFor-2)"?>
/// ```html
/// <hero-detail *ngFor="let hero of heroes" [hero]="hero"></hero-detail>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (inside-ngfor)"?>
/// ```html
/// <div *ngFor="let hero of heroes; let i=index; let odd=odd; trackBy: trackById"
///      [class.odd]="odd">
///   ({{i}}) {{hero.name}}
/// </div>
///
/// <template ngFor let-hero [ngForOf]="heroes" let-i="index" let-odd="odd"
///           [ngForTrackBy]="trackById">
///   <div [class.odd]="odd">({{i}}) {{hero.name}}</div>
/// </template>
/// ```
///
/// For details, see the [`ngFor` discussion in the Template Syntax][guide]
/// page.
///
/// [guide]: https://webdev.dartlang.org/angular/guide/template-syntax.html#ngFor
@Directive(
  selector: '[ngFor][ngForOf]',
)
class NgFor implements DoCheck {
  final ViewContainerRef _viewContainer;

  DefaultIterableDiffer _differ;
  Iterable _ngForOf;
  TrackByFn _ngForTrackBy;
  TemplateRef _templateRef;

  NgFor(this._viewContainer, this._templateRef);

  @Input()
  set ngForOf(Iterable value) {
    _ngForOf = value;
    if (_differ == null && value != null) {
      _differ = new DefaultIterableDiffer(_ngForTrackBy);
    }
  }

  @Input()
  set ngForTemplate(TemplateRef value) {
    if (value != null) {
      _templateRef = value;
    }
  }

  /// Optionally; set a function used to determine uniqueness of an element.
  ///
  /// See [TrackByFn] for more details on how to use this parameter type.
  @Input()
  set ngForTrackBy(TrackByFn value) {
    _ngForTrackBy = value;
    if (_ngForOf != null) {
      if (_differ == null) {
        _differ = new DefaultIterableDiffer(_ngForTrackBy);
      } else {
        _differ = _differ.clone(_ngForTrackBy);
      }
    }
  }

  @override
  void ngDoCheck() {
    if (_differ != null) {
      var changes = _differ.diff(_ngForOf);
      if (changes != null) _applyChanges(changes);
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
            _viewContainer.insertEmbeddedView(_templateRef, currentIndex);
        var tuple = new RecordViewTuple(item, view);
        insertTuples.add(tuple);
      } else if (currentIndex == null) {
        _viewContainer.remove(adjustedPreviousIndex);
      } else {
        var view = _viewContainer.get(adjustedPreviousIndex);
        _viewContainer.move(view, currentIndex);
        var tuple = new RecordViewTuple(item, view);
        insertTuples.add(tuple);
      }
    });

    for (var i = 0; i < insertTuples.length; i++) {
      _perViewChange(insertTuples[i].view, insertTuples[i].record);
    }
    for (var i = 0, len = _viewContainer.length; i < len; i++) {
      var viewRef = _viewContainer.get(i);
      viewRef.setLocal('first', identical(i, 0));
      viewRef.setLocal('last', identical(i, len - 1));
      viewRef.setLocal('index', i);
      viewRef.setLocal('count', len);
    }
    changes.forEachIdentityChange((record) {
      var viewRef = _viewContainer.get(record.currentIndex);
      viewRef.setLocal('\$implicit', record.item);
    });
  }

  void _perViewChange(EmbeddedViewRef view, CollectionChangeRecord record) {
    view.setLocal('\$implicit', record.item);
    view.setLocal('even', record.currentIndex.isEven);
    view.setLocal('odd', record.currentIndex.isOdd);
  }
}

class RecordViewTuple {
  final EmbeddedViewRef view;
  final CollectionChangeRecord record;
  RecordViewTuple(this.record, this.view);
}
