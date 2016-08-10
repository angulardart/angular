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

/// The `NgStyle` directive changes styles based on a result of expression
/// evaluation.
///
/// An expression assigned to the `ngStyle` property must evaluate to an object
/// and the corresponding element styles are updated based on changes to this
/// object. Style names to update are taken from the object's keys, and values
/// - from the corresponding object's values.
///
/// ### Syntax
///
/// - `<div [ngStyle]="{'font-style': style}"></div>`
/// - `<div [ngStyle]="styleExp"></div>` - here the `styleExp` must evaluate to
/// an object
///
/// ### Example:
///
/// ```dart
/// import 'angular2/core.dart' Component;
/// import 'angular2/common.dart' NgStyle;
///
/// @Component(
///  selector: 'ngStyle-example',
///  template: '''
///    <h1 [ngStyle]="{'font-style': style, 'font-size': size, 'font-weight': weight}">
///      Change style of this text!
///    </h1>
///
///    <hr>
///
///    <label>Italic: <input type="checkbox" (change)="changeStyle($event)"></label>
///    <label>Bold: <input type="checkbox" (change)="changeWeight($event)"></label>
///    <label>Size: <input type="text" [value]="size" (change)="size = $event.target.value"></label>
///  ''',
///  directives: const [NgStyle]
/// )
/// class NgStyleExample {
///    String style = 'normal';
///    String weight = 'normal';
///    String size = '20px';
///
///    void changeStyle(dynamic event) {
///      style = event.target.checked ? 'italic' : 'normal';
///    }
///
///    void changeWeight(dynamic event) {
///      weight = event.target.checked ? 'bold' : 'normal';
///    }
/// }
/// ```
///
/// In this example the `font-style`, `font-size` and `font-weight` styles will
/// be updated based on the `style` property's value changes.
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
