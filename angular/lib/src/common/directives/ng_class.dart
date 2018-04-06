import 'dart:html';
import 'package:angular/core.dart' show DoCheck, Input, OnDestroy, Directive;
import 'package:angular/src/core/change_detection/differs/default_iterable_differ.dart';
import 'package:angular/src/core/change_detection/differs/default_keyvalue_differ.dart';
import 'package:angular/src/runtime.dart';

/// The [NgClass] directive conditionally adds and removes CSS classes on an
/// HTML element based on an expression's evaluation result.
///
/// The result of an expression evaluation is interpreted differently depending
/// on type of the expression evaluation result:
///
/// - [String] - all the CSS classes listed in a string (space delimited) are
///   added
/// - [List]   - all the CSS classes (List elements) are added
/// - [Object] - each key corresponds to a CSS class name while values are
///   interpreted as expressions evaluating to [bool]. If a given expression
///   evaluates to [true] a corresponding CSS class is added - otherwise it is
///   removed.
///
/// While the [NgClass] directive can interpret expressions evaluating to
/// [String], [Array] or [Object], the [Object]-based version is the most often
/// used and has an advantage of keeping all the CSS class names in a template.
///
/// ### Examples
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgClass-1)"?>
/// ```html
/// <div [ngClass]="currentClasses">This div is initially saveable, unchanged, and special</div>
/// ```
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.dart (setClasses)"?>
/// ```dart
/// Map<String, bool> currentClasses = <String, bool>{};
/// void setCurrentClasses() {
///   currentClasses = <String, bool>{
///     'saveable': canSave,
///     'modified': !isUnchanged,
///     'special': isSpecial
///   };
/// }
/// ```
///
/// Try the [live example][ex].
/// For details, see the [`ngClass` discussion in the Template Syntax][guide]
/// page.
///
/// [ex]: https://webdev.dartlang.org/examples/template-syntax/#ngClass
/// [guide]: https://webdev.dartlang.org/angular/guide/template-syntax.html#ngClass
@Directive(
  selector: '[ngClass]',
)
class NgClass implements DoCheck, OnDestroy {
  // Separator used to split string to parts - can be any number of
  // whitespaces, new lines or tabs.
  static RegExp _separator;
  Element _ngEl;
  DefaultIterableDiffer _iterableDiffer;
  DefaultKeyValueDiffer _keyValueDiffer;
  List<String> _initialClasses = [];
  dynamic _rawClass;
  NgClass(this._ngEl);

  @Input('class')
  set initialClasses(String v) {
    this._applyInitialClasses(true);
    this._initialClasses = v is String ? v.split(' ') : [];
    this._applyInitialClasses(false);
    this._applyClasses(this._rawClass, false);
  }

  @Input('ngClass')
  set rawClass(
      dynamic /* String | List < String > | Set< String > | Map < String , dynamic > */ v) {
    this._cleanupClasses(this._rawClass);
    if (v is String) {
      v = v.split(' ');
    }
    this._rawClass = v;
    this._iterableDiffer = null;
    this._keyValueDiffer = null;
    if (v != null) {
      if (v is Iterable) {
        _iterableDiffer = new DefaultIterableDiffer();
      } else {
        _keyValueDiffer = new DefaultKeyValueDiffer();
      }
    }
  }

  @override
  void ngDoCheck() {
    if (_iterableDiffer != null) {
      var changes = _iterableDiffer.diff(unsafeCast(_rawClass));
      if (changes != null) {
        _applyIterableChanges(changes);
      }
    }
    if (_keyValueDiffer != null) {
      var changes = _keyValueDiffer.diff(unsafeCast(_rawClass));
      if (changes != null) {
        _applyKeyValueChanges(changes);
      }
    }
  }

  @override
  void ngOnDestroy() {
    _cleanupClasses(_rawClass);
  }

  void _cleanupClasses(dynamic /* Iterable | Map */ rawClassVal) {
    _applyClasses(rawClassVal, true);
    _applyInitialClasses(false);
  }

  void _applyKeyValueChanges(DefaultKeyValueDiffer changes) {
    changes.forEachAddedItem((KeyValueChangeRecord record) {
      _toggleClass(unsafeCast(record.key), unsafeCast(record.currentValue));
    });
    changes.forEachChangedItem((KeyValueChangeRecord record) {
      _toggleClass(unsafeCast(record.key), unsafeCast(record.currentValue));
    });
    changes.forEachRemovedItem((KeyValueChangeRecord record) {
      if (record.previousValue != null) {
        _toggleClass(unsafeCast(record.key), false);
      }
    });
  }

  void _applyIterableChanges(DefaultIterableDiffer changes) {
    changes.forEachAddedItem((CollectionChangeRecord record) {
      _toggleClass(unsafeCast(record.item), true);
    });
    changes.forEachRemovedItem((CollectionChangeRecord record) {
      _toggleClass(unsafeCast(record.item), false);
    });
  }

  void _applyInitialClasses(bool isCleanup) {
    for (var className in _initialClasses) {
      _toggleClass(className, !isCleanup);
    }
  }

  /// If [rawClassVal] is an Iterable, it should only contain string values,
  /// but it is OK if the Iterable itself is Iterable<dynamic> or
  /// Iterable<Object> since we need to walk it in this method anyway.
  ///
  /// Likewise, if [rawClassVal] is a Map, its keys should all be strings.
  void _applyClasses(dynamic /* Iterable | Map */ rawClassVal, bool isCleanup) {
    if (rawClassVal != null) {
      if (rawClassVal is List) {
        for (int i = 0, len = rawClassVal.length; i < len; i++) {
          _toggleClass(unsafeCast(rawClassVal[i]), !isCleanup);
        }
      } else if (rawClassVal is Iterable) {
        for (var className in rawClassVal) {
          _toggleClass(unsafeCast(className), !isCleanup);
        }
      } else {
        (rawClassVal as Map).forEach((className, expVal) {
          if (expVal != null) {
            _toggleClass(unsafeCast(className), !isCleanup);
          }
        });
      }
    }
  }

  void _toggleClass(String className, bool enabled) {
    className = className.trim();
    if (className.isEmpty) return;
    Element el = _ngEl;
    var classList = el.classes;
    if (className.indexOf(' ') > -1) {
      _separator ??= new RegExp(r'\s+');
      var classes = className.split(_separator);
      for (var i = 0, len = classes.length; i < len; i++) {
        if (enabled) {
          classList.add(classes[i]);
        } else {
          classList.remove(classes[i]);
        }
      }
    } else {
      if (enabled) {
        classList.add(className);
      } else {
        classList.remove(className);
      }
    }
  }
}
