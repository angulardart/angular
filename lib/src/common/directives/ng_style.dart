import "package:angular2/core.dart"
    show
        DoCheck,
        KeyValueDiffer,
        KeyValueDiffers,
        ElementRef,
        Directive,
        Renderer;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;

import "../../core/change_detection/differs/default_keyvalue_differ.dart"
    show KeyValueChangeRecord;

/// The `NgStyle` directive changes an element's style based on the bound style
/// expression:
///
///     <div [ngStyle]="styleExp"></div>
///
/// _styleExp_ must evaluate to a `Map<String, String>`. Element style properties
/// are set based on the map entries: each _key_:_value_ pair identifies a
/// style property _name_ and its _value_.
///
/// See the [Template Syntax section on `NgStyle`][guide] for more details.
///
/// ### Examples
///
/// A [Map] literal can be used as a style expression
///
///     <div [ngStyle]="{'font-style': 'italic'}"></div>
///
/// though it is better practice to bind to a component field or method. Try the
/// [live example][ex] from the [Template Syntax][guide] chapter. Here are the
/// relevant excerpts from the example's template and component class:
///
/// {@example docs/template-syntax/lib/app_component.html region=NgStyle}
///
/// {@example docs/template-syntax/lib/app_component.dart region=NgStyle}
///
/// In this example, the first paragraph's `font-style`, `font-weight` and
/// `font-size` style properties will be updated as the user changes the
/// `<input>` elements.
///
/// [guide]: docs/guide/template-syntax.html#!#ngStyle
/// [ex]: examples/template-syntax/#ngStyle
@Directive(selector: "[ngStyle]", inputs: const ["rawStyle: ngStyle"])
class NgStyle implements DoCheck {
  KeyValueDiffers _differs;
  ElementRef _ngEl;
  Renderer _renderer;
  Map<String, String> _rawStyle;
  KeyValueDiffer _differ;
  NgStyle(this._differs, this._ngEl, this._renderer) {}
  set rawStyle(Map<String, String> v) {
    this._rawStyle = v;
    if (isBlank(this._differ) && isPresent(v)) {
      this._differ = this._differs.find(this._rawStyle).create(null);
    }
  }

  ngDoCheck() {
    if (isPresent(this._differ)) {
      var changes = this._differ.diff(this._rawStyle);
      if (isPresent(changes)) {
        this._applyChanges(changes);
      }
    }
  }

  void _applyChanges(dynamic changes) {
    changes.forEachAddedItem((KeyValueChangeRecord record) {
      this._setStyle(record.key, record.currentValue);
    });
    changes.forEachChangedItem((KeyValueChangeRecord record) {
      this._setStyle(record.key, record.currentValue);
    });
    changes.forEachRemovedItem((KeyValueChangeRecord record) {
      this._setStyle(record.key, null);
    });
  }

  void _setStyle(String name, String val) {
    this._renderer.setElementStyle(this._ngEl.nativeElement, name, val);
  }
}
