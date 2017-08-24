import 'package:angular/core.dart'
    show Directive, Input, ViewContainerRef, ViewRef, TemplateRef, Visibility;

/// Creates and inserts an embedded view based on a prepared `TemplateRef`.
///
/// ### Syntax
/// - `<template [ngTemplateOutlet]="templateRefExpression"></template>`
@Directive(selector: '[ngTemplateOutlet]', visibility: Visibility.none)
class NgTemplateOutlet {
  final ViewContainerRef _viewContainerRef;

  ViewRef _insertedViewRef;

  NgTemplateOutlet(this._viewContainerRef);

  /// Sets the DOM to render the result of [templateRef].
  ///
  /// If the template is changed, the previous template is removed first.
  @Input()
  set ngTemplateOutlet(TemplateRef templateRef) {
    if (_insertedViewRef != null) {
      _viewContainerRef.remove(_viewContainerRef.indexOf(_insertedViewRef));
    }
    if (templateRef != null) {
      _insertedViewRef = _viewContainerRef.createEmbeddedView(templateRef);
    }
  }
}
