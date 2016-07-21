import "package:angular2/core.dart"
    show Directive, Input, ViewContainerRef, ViewRef, TemplateRef;
import "package:angular2/src/facade/lang.dart" show isPresent;

/**
 * Creates and inserts an embedded view based on a prepared `TemplateRef`.
 *
 * ### Syntax
 * - `<template [ngTemplateOutlet]="templateRefExpression"></template>`
 */
@Directive(selector: "[ngTemplateOutlet]")
class NgTemplateOutlet {
  ViewContainerRef _viewContainerRef;
  ViewRef _insertedViewRef;
  NgTemplateOutlet(this._viewContainerRef) {}
  @Input()
  set ngTemplateOutlet(TemplateRef templateRef) {
    if (isPresent(this._insertedViewRef)) {
      this
          ._viewContainerRef
          .remove(this._viewContainerRef.indexOf(this._insertedViewRef));
    }
    if (isPresent(templateRef)) {
      this._insertedViewRef =
          this._viewContainerRef.createEmbeddedView(templateRef);
    }
  }
}
