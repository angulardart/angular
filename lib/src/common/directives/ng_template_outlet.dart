import "package:angular2/core.dart"
    show Directive, Input, ViewContainerRef, ViewRef, TemplateRef;

/// Creates and inserts an embedded view based on a prepared `TemplateRef`.
///
/// ### Syntax
/// - `<template [ngTemplateOutlet]="templateRefExpression"></template>`
@Directive(selector: "[ngTemplateOutlet]")
class NgTemplateOutlet {
  final ViewContainerRef _viewContainerRef;
  ViewRef _insertedViewRef;
  NgTemplateOutlet(this._viewContainerRef);
  @Input()
  set ngTemplateOutlet(TemplateRef templateRef) {
    if (_insertedViewRef != null) {
      _viewContainerRef
          .remove(this._viewContainerRef.indexOf(this._insertedViewRef));
    }
    if (templateRef != null) {
      this._insertedViewRef =
          this._viewContainerRef.createEmbeddedView(templateRef);
    }
  }
}
