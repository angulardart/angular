import 'package:angular2/core.dart'
    show Directive, ViewContainerRef, TemplateRef;
import 'package:angular2/src/core/linker/app_view_utils.dart';
import 'package:angular2/src/facade/lang.dart';

/// Causes an element and its contents to be conditionally added/removed from
/// the DOM based on the value of the given boolean template expression.
///
/// For details, see the [`ngIf` discussion in the Template Syntax][guide] page.
///
/// ### Examples
///
/// ```html
/// <!-- {@source "docs/template-syntax/lib/app_component.html" region="NgIf-1"} -->
/// <div *ngIf="currentHero != null">Hello, {{currentHero.firstName}}</div>
/// ```
///
/// ```html
/// <!-- {@source "docs/template-syntax/lib/app_component.html" region="Template-2"} -->
/// <template [ngIf]="currentHero != null">
///   <hero-detail [hero]="currentHero"></hero-detail>
/// </template>
/// ```
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

    // In dev-mode, use `checkBinding`. In prod-mode, use `looseIdentical`.
    if (assertionsEnabled()) {
      if (!checkBinding(newCondition, _prevCondition)) return;
    } else {
      if (looseIdentical(newCondition, _prevCondition)) return;
    }

    if (newCondition) {
      _viewContainer.createEmbeddedView(_templateRef);
    } else {
      _viewContainer.clear();
    }
    _prevCondition = newCondition;
  }
}
