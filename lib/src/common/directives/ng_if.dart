import 'package:angular2/core.dart'
    show Directive, ViewContainerRef, TemplateRef;

/// Causes an element and its contents to be added/removed from the DOM
/// conditionally, based on the value of the supplied boolean template
/// expression.
///
/// See the [Template Syntax section on `ngIf`][guide] for more details.
///
/// ### Examples
///
/// {@example docs/template-syntax/lib/app_component.html region=NgIf-1}
///
/// {@example docs/template-syntax/lib/app_component.html region=Template-2}
///
/// [guide]: docs/guide/template-syntax.html#ngIf
@Directive(selector: "[ngIf]", inputs: const ["ngIf"])
class NgIf {
  final TemplateRef _templateRef;
  final ViewContainerRef _viewContainer;

  bool _prevCondition = false;

  NgIf(this._viewContainer, this._templateRef);

  /// Whether the content of the directive should be visible.
  set ngIf(bool newCondition) {
    // Legacy support for cases where `null` is still passed to NgIf.
    newCondition = newCondition == true;
    if (identical(newCondition, _prevCondition)) return;
    if (newCondition) {
      _viewContainer.createEmbeddedView(_templateRef);
    } else {
      _viewContainer.clear();
    }
    _prevCondition = newCondition;
  }
}
