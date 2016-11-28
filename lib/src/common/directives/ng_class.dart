import "package:angular2/core.dart"
    show
        DoCheck,
        OnDestroy,
        Directive,
        ElementRef,
        IterableDiffers,
        KeyValueDiffers,
        IterableDiffer,
        KeyValueDiffer,
        CollectionChangeRecord,
        KeyValueChangeRecord;

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
/// {@example docs/template-syntax/lib/app_component.html region=NgClass-1}
///
/// {@example docs/template-syntax/lib/app_component.dart region=setClasses}
///
/// Try the [live example][ex].
/// See the [Template Syntax section on `ngClass`][guide] for more details.
///
/// [ex]: examples/template-syntax/#ngClass
/// [guide]: docs/guide/template-syntax.html#ngClass
@Directive(
    selector: "[ngClass]",
    inputs: const ["rawClass: ngClass", "initialClasses: class"])
class NgClass implements DoCheck, OnDestroy {
  // Separator used to split string to parts - can be any number of
  // whitespaces, new lines or tabs.
  static RegExp _separator;
  IterableDiffers _iterableDiffers;
  KeyValueDiffers _keyValueDiffers;
  ElementRef _ngEl;
  IterableDiffer _iterableDiffer;
  KeyValueDiffer _keyValueDiffer;
  List<String> _initialClasses = [];
  dynamic /* List < String > | Set< String > */ _rawClass;
  NgClass(this._iterableDiffers, this._keyValueDiffers, this._ngEl);

  set initialClasses(String v) {
    this._applyInitialClasses(true);
    this._initialClasses = v is String ? v.split(" ") : [];
    this._applyInitialClasses(false);
    this._applyClasses(this._rawClass, false);
  }

  set rawClass(
      dynamic /* String | List < String > | Set< String > | Map < String , dynamic > */ v) {
    this._cleanupClasses(this._rawClass);
    if (v is String) {
      v = v.split(' ');
    }
    this._rawClass = (v as dynamic /* List < String > | Set< String > */);
    this._iterableDiffer = null;
    this._keyValueDiffer = null;
    if (v != null) {
      if (v is Iterable) {
        _iterableDiffer = _iterableDiffers.find(v).create(null);
      } else {
        _keyValueDiffer = _keyValueDiffers.find(v).create(null);
      }
    }
  }

  @override
  void ngDoCheck() {
    if (_iterableDiffer != null) {
      var changes = _iterableDiffer.diff(_rawClass);
      if (changes != null) {
        _applyIterableChanges(changes);
      }
    }
    if (_keyValueDiffer != null) {
      var changes = _keyValueDiffer.diff(_rawClass);
      if (changes != null) {
        _applyKeyValueChanges(changes);
      }
    }
  }

  @override
  void ngOnDestroy() {
    _cleanupClasses(_rawClass);
  }

  void _cleanupClasses(
      dynamic /* List < String > | Set< String > | Map < String , dynamic > */ rawClassVal) {
    _applyClasses(rawClassVal, true);
    _applyInitialClasses(false);
  }

  void _applyKeyValueChanges(dynamic changes) {
    changes.forEachAddedItem((KeyValueChangeRecord record) {
      _toggleClass(record.key, record.currentValue);
    });
    changes.forEachChangedItem((KeyValueChangeRecord record) {
      _toggleClass(record.key, record.currentValue);
    });
    changes.forEachRemovedItem((KeyValueChangeRecord record) {
      if (record.previousValue) {
        _toggleClass(record.key, false);
      }
    });
  }

  void _applyIterableChanges(dynamic changes) {
    changes.forEachAddedItem((CollectionChangeRecord record) {
      _toggleClass(record.item, true);
    });
    changes.forEachRemovedItem((CollectionChangeRecord record) {
      _toggleClass(record.item, false);
    });
  }

  void _applyInitialClasses(bool isCleanup) {
    _initialClasses.forEach((className) => _toggleClass(className, !isCleanup));
  }

  void _applyClasses(
      dynamic /* List < String > | Set< String > | Map < String , dynamic > */ rawClassVal,
      bool isCleanup) {
    if (rawClassVal != null) {
      if (rawClassVal is Iterable) {
        ((rawClassVal as Iterable<String>))
            .forEach((className) => _toggleClass(className, !isCleanup));
      } else {
        (rawClassVal as Map<String, dynamic>).forEach((className, expVal) {
          if (expVal != null) {
            _toggleClass(className, !isCleanup);
          }
        });
      }
    }
  }

  void _toggleClass(String className, bool enabled) {
    className = className.trim();
    if (className.length > 0) {
      if (className.indexOf(" ") > -1) {
        _separator ??= new RegExp(r'\s+');
        var classes = className.split(_separator);
        for (var i = 0, len = classes.length; i < len; i++) {
          if (enabled) {
            _ngEl.nativeElement.classes.add(classes[i]);
          } else {
            _ngEl.nativeElement.classes.remove(classes[i]);
          }
        }
      } else {
        if (enabled) {
          _ngEl.nativeElement.classes.add(className);
        } else {
          _ngEl.nativeElement.classes.remove(className);
        }
      }
    }
  }
}
