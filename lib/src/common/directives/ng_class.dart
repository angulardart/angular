import "package:angular2/core.dart"
    show
        DoCheck,
        OnDestroy,
        Directive,
        ElementRef,
        IterableDiffers,
        KeyValueDiffers,
        Renderer,
        IterableDiffer,
        KeyValueDiffer,
        CollectionChangeRecord,
        KeyValueChangeRecord;
import "package:angular2/src/facade/collection.dart" show isListLikeIterable;
import "package:angular2/src/facade/lang.dart"
    show isPresent, isString, isArray;

/// The `NgClass` directive conditionally adds and removes CSS classes on an
/// HTML element based on an expression's evaluation result.
///
/// The result of an expression evaluation is interpreted differently depending
/// on type of the expression evaluation result:
/// - `String` - all the CSS classes listed in a string (space delimited) are
/// added
/// - `List` - all the CSS classes (List elements) are added
/// - `Map` - each key corresponds to a CSS class name while values are
/// interpreted as expressions evaluating to `Boolean`. If a given expression
/// evaluates to `true` a corresponding CSS class is added - otherwise it is
/// removed.
///
/// While the `NgClass` directive can interpret expressions evaluating to
/// `String`, `List` or `Map`, the `Map`-based version is the most often used
/// and has an advantage of keeping all the CSS class names in a template.
///
/// ### Example:
///
/// ```dart
/// import 'angular2/core.dart' show Component;
/// import 'angular2/common.dart' show NgClass;
///
/// @Component(
///   selector: 'toggle-button',
///   inputs: const ['isDisabled'],
///   template: '''
///      <div class="button" [ngClass]="{active: isOn, disabled: isDisabled}"
///          (click)="toggle(!isOn)">
///          Click me!
///      </div>''',
///   styles: const ['''
///     .button {
///       width: 120px;
///       border: medium solid black;
///     }
///
///     .active {
///       background-color: red;
///    }
///
///     .disabled {
///       color: gray;
///       border: medium solid gray;
///     }
///   ''']
///   directives: const [NgClass]
/// )
/// class ToggleButton {
///   bool isOn = false;
///   bool isDisabled = false;
///
///   void toggle(bool newState) {
///     if (!isDisabled) {
///       isOn = newState;
///     }
///   }
/// }
/// ```
@Directive(
    selector: "[ngClass]",
    inputs: const ["rawClass: ngClass", "initialClasses: class"])
class NgClass implements DoCheck, OnDestroy {
  IterableDiffers _iterableDiffers;
  KeyValueDiffers _keyValueDiffers;
  ElementRef _ngEl;
  Renderer _renderer;
  IterableDiffer _iterableDiffer;
  KeyValueDiffer _keyValueDiffer;
  List<String> _initialClasses = [];
  dynamic /* List < String > | Set< String > */ _rawClass;
  NgClass(this._iterableDiffers, this._keyValueDiffers, this._ngEl,
      this._renderer) {}
  set initialClasses(String v) {
    this._applyInitialClasses(true);
    this._initialClasses = isPresent(v) && isString(v) ? v.split(" ") : [];
    this._applyInitialClasses(false);
    this._applyClasses(this._rawClass, false);
  }

  set rawClass(
      dynamic /* String | List < String > | Set< String > | Map < String , dynamic > */ v) {
    this._cleanupClasses(this._rawClass);
    if (isString(v)) {
      v = ((v as String)).split(" ");
    }
    this._rawClass = (v as dynamic /* List < String > | Set< String > */);
    this._iterableDiffer = null;
    this._keyValueDiffer = null;
    if (isPresent(v)) {
      if (isListLikeIterable(v)) {
        this._iterableDiffer = this._iterableDiffers.find(v).create(null);
      } else {
        this._keyValueDiffer = this._keyValueDiffers.find(v).create(null);
      }
    }
  }

  void ngDoCheck() {
    if (isPresent(this._iterableDiffer)) {
      var changes = this._iterableDiffer.diff(this._rawClass);
      if (isPresent(changes)) {
        this._applyIterableChanges(changes);
      }
    }
    if (isPresent(this._keyValueDiffer)) {
      var changes = this._keyValueDiffer.diff(this._rawClass);
      if (isPresent(changes)) {
        this._applyKeyValueChanges(changes);
      }
    }
  }

  void ngOnDestroy() {
    this._cleanupClasses(this._rawClass);
  }

  void _cleanupClasses(
      dynamic /* List < String > | Set< String > | Map < String , dynamic > */ rawClassVal) {
    this._applyClasses(rawClassVal, true);
    this._applyInitialClasses(false);
  }

  void _applyKeyValueChanges(dynamic changes) {
    changes.forEachAddedItem((KeyValueChangeRecord record) {
      this._toggleClass(record.key, record.currentValue);
    });
    changes.forEachChangedItem((KeyValueChangeRecord record) {
      this._toggleClass(record.key, record.currentValue);
    });
    changes.forEachRemovedItem((KeyValueChangeRecord record) {
      if (record.previousValue) {
        this._toggleClass(record.key, false);
      }
    });
  }

  void _applyIterableChanges(dynamic changes) {
    changes.forEachAddedItem((CollectionChangeRecord record) {
      this._toggleClass(record.item, true);
    });
    changes.forEachRemovedItem((CollectionChangeRecord record) {
      this._toggleClass(record.item, false);
    });
  }

  _applyInitialClasses(bool isCleanup) {
    this
        ._initialClasses
        .forEach((className) => this._toggleClass(className, !isCleanup));
  }

  _applyClasses(
      dynamic /* List < String > | Set< String > | Map < String , dynamic > */ rawClassVal,
      bool isCleanup) {
    if (isPresent(rawClassVal)) {
      if (isArray(rawClassVal)) {
        ((rawClassVal as List<String>))
            .forEach((className) => this._toggleClass(className, !isCleanup));
      } else if (rawClassVal is Set) {
        ((rawClassVal as Set<String>))
            .forEach((className) => this._toggleClass(className, !isCleanup));
      } else {
        (rawClassVal as Map<String, dynamic>).forEach((className, expVal) {
          if (expVal != null) {
            this._toggleClass(className, !isCleanup);
          }
        });
      }
    }
  }

  void _toggleClass(String className, bool enabled) {
    className = className.trim();
    if (className.length > 0) {
      if (className.indexOf(" ") > -1) {
        var classes = className.split(new RegExp(r'\s+'));
        for (var i = 0, len = classes.length; i < len; i++) {
          this
              ._renderer
              .setElementClass(this._ngEl.nativeElement, classes[i], enabled);
        }
      } else {
        this
            ._renderer
            .setElementClass(this._ngEl.nativeElement, className, enabled);
      }
    }
  }
}
