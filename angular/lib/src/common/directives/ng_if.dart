import 'package:angular/core.dart' show Directive, Input;
import 'package:angular/src/core/linker.dart'
    show ViewContainerRef, TemplateRef;
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/runtime.dart';

/// Causes an element and its contents to be conditionally added/removed from
/// the DOM based on the value of the given boolean template expression.
///
/// For details, see the [`ngIf` discussion in the Template Syntax][guide] page.
///
/// ### Examples
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgIf-1)"?>
/// ```html
/// <hero-detail *ngIf="isActive"></hero-detail>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (asterisk)"?>
/// ```html
/// <div *ngIf="hero != null" >{{hero.name}}</div>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (ngif-template-attr)"?>
/// ```html
/// <div template="ngIf hero != null">{{hero.name}}</div>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (ngif-template)"?>
/// ```html
/// <template [ngIf]="hero != null">
///   <div>{{hero.name}}</div>
/// </template>
/// ```
///
/// [guide]: https://webdev.dartlang.org/angular/guide/template-syntax.html#ngIf
@Directive(
  selector: '[ngIf]',
)
class NgIf {
  final TemplateRef _templateRef;
  final ViewContainerRef _viewContainer;

  bool _prevCondition = false;

  NgIf(this._viewContainer, this._templateRef);

  /// Whether the content of the directive should be visible.
  @Input()
  set ngIf(bool newCondition) {
    // Legacy support for cases where `null` is still passed to NgIf.
    newCondition = newCondition == true;
    // In dev-mode, use `checkBinding`. In prod-mode, use `looseIdentical`.
    if (isDevMode) {
      if (!checkBinding(newCondition, _prevCondition)) return;
    } else {
      if (identical(newCondition, _prevCondition)) return;
    }
    if (newCondition) {
      _viewContainer.createEmbeddedView(_templateRef);
    } else {
      _viewContainer.clear();
    }
    _prevCondition = newCondition;
  }
}
