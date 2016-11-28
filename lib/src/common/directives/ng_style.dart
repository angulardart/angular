import 'dart:html';

import "package:angular2/core.dart"
    show DoCheck, KeyValueDiffer, KeyValueDiffers, ElementRef, Directive;

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
/// Try the [live example][ex] from the [Template Syntax][guide] page. Here are
/// the relevant excerpts from the example's template and the corresponding
/// component class:
///
/// {@example docs/template-syntax/lib/app_component.html region=NgStyle}
///
/// {@example docs/template-syntax/lib/app_component.dart region=NgStyle}
///
/// In this example, user changes to the `<input>` elements result in updates
/// to the corresponding style properties of the first paragraph.
///
/// A [Map] literal can be used as a style expression:
///
///     <div [ngStyle]="{'font-style': 'italic'}"></div>
///
/// A better practice, however, is to bind to a component field or method, as
/// in the binding to `setStyle()` above.
///
/// [guide]: docs/guide/template-syntax.html#ngStyle
/// [ex]: examples/template-syntax/#ngStyle
@Directive(selector: "[ngStyle]", inputs: const ["rawStyle: ngStyle"])
class NgStyle implements DoCheck {
  final KeyValueDiffers _differs;
  final Element _ngElement;
  Map<String, String> _rawStyle;
  KeyValueDiffer _differ;

  NgStyle(this._differs, ElementRef elementRef)
      : _ngElement = elementRef.nativeElement;

  set rawStyle(Map<String, String> v) {
    this._rawStyle = v;
    if (_differ == null && v != null) {
      this._differ = this._differs.find(this._rawStyle).create(null);
    }
  }

  @override
  void ngDoCheck() {
    if (_differ == null) return;
    var changes = _differ.diff(_rawStyle);
    if (changes == null) return;
    changes.forEachAddedItem((KeyValueChangeRecord record) {
      _ngElement.style.setProperty(record.key, record.currentValue);
    });
    changes.forEachChangedItem((KeyValueChangeRecord record) {
      _ngElement.style.setProperty(record.key, record.currentValue);
    });
    changes.forEachRemovedItem((KeyValueChangeRecord record) {
      _ngElement.style.setProperty(record.key, record.currentValue);
    });
  }
}
