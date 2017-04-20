import 'dart:html';

import 'package:angular2/core.dart' show DoCheck, ElementRef, Directive;

import '../../core/change_detection/differs/map_differ.dart';

/// The `NgStyle` directive changes an element's style based on the bound style
/// expression:
///
///     <div [ngStyle]="styleExp"></div>
///
/// _styleExp_ must evaluate to a `Map<String, String>`. Element style properties
/// are set based on the map entries: each _key_:_value_ pair identifies a
/// style property _name_ and its _value_.
///
/// For details, see the [`ngStyle` discussion in the Template Syntax][guide]
/// page.
///
/// ### Examples
///
/// Try the [live example][ex] from the [Template Syntax][guide] page. Here are
/// the relevant excerpts from the example's template and the corresponding
/// component class:
///
/// ```html
/// <!-- {@source "docs/template-syntax/lib/app_component.html" region="NgStyle-2"} -->
/// <div [ngStyle]="currentStyles">
///   This div is initially italic, normal weight, and extra large (24px).
/// </div>
/// ```
///
/// ```dart
/// // {@source "docs/template-syntax/lib/app_component.dart" region="setStyles"}
/// Map<String, String> currentStyles = <String, String>{};
/// void setCurrentStyles() {
///   currentStyles = <String, String>{
///     'font-style': canSave ? 'italic' : 'normal',
///     'font-weight': !isUnchanged ? 'bold' : 'normal',
///     'font-size': isSpecial ? '24px' : '12px'
///   };
/// }
/// ```
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
/// [guide]: https://webdev.dartlang.org/angular/guide/template-syntax.html#ngStyle
/// [ex]: http://angular-examples.github.io/template-syntax/#ngStyle
@Directive(selector: "[ngStyle]", inputs: const ["rawStyle: ngStyle"])
class NgStyle implements DoCheck {
  final Element _element;
  Map<String, String> _rawStyle;
  MapDiffer<String, String> _differ;

  NgStyle(ElementRef elementRef) : _element = elementRef.nativeElement;

  set rawStyle(Map<String, String> value) {
    _rawStyle = value;
    if (_differ == null && value != null) {
      _differ = new MapDiffer<String, String>();
    }
  }

  @override
  void ngDoCheck() {
    if (_differ != null && _differ.diff(_rawStyle)) {
      _differ.forEachChange(_element.style.setProperty);
      _differ.forEachRemoval(_element.style.removeProperty);
    }
  }
}
