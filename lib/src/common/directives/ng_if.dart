import 'package:angular2/core.dart'
    show Directive, ViewContainerRef, TemplateRef;

/// Causes an element and its contents to be conditionally added/removed from
/// the DOM based on the value of the given boolean template expression.
///
/// For details, see the [`ngIf` discussion in the Template Syntax][guide] page.
///
/// ### Examples
///
/// ```html
/// <!-- {@source "docs/template-syntax/lib/app_component.html" region="NgIf-1"} -->
/// <hero-detail *ngIf="isActive"></hero-detail>
/// ```
///
/// ```html
/// <!-- {@source "docs/structural-directives/lib/app_component.html" region="asterisk"} -->
/// <div *ngIf="hero != null" >{{hero.name}}</div>
/// ```
///
/// ```html
/// <!-- {@source "docs/structural-directives/lib/app_component.html" region="ngif-template-attr"} -->
/// <div template="ngIf hero != null">{{hero.name}}</div>
/// ```
///
/// ```html
/// <!-- {@source "docs/structural-directives/lib/app_component.html" region="ngif-template"} -->
/// <template [ngIf]="hero != null">
///   <div>{{hero.name}}</div>
/// </template>
/// ```
///
/// [guide]: https://webdev.dartlang.org/angular/guide/template-syntax.html#ngIf
@Directive(selector: '[ngIf]', inputs: const ['ngIf'])
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
