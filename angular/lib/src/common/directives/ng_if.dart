import 'package:angular/core.dart' show Directive, Input;
import 'package:angular/src/core/linker.dart'
    show ViewContainerRef, TemplateRef;
import 'package:angular/src/core/linker/app_view_utils.dart';

/// Causes an element and its contents to be conditionally added/removed from
/// the DOM based on the value of the given boolean template expression.
///
/// For details, see the [`ngIf` discussion in the Template Syntax][guide] page.
///
/// ### Examples
///
/// <?code-excerpt "examples/hacker_news_pwa/lib/src/item_detail_component.html"?>
/// ```html
/// <!-- Loading view -->
/// <div *ngIf="item == null" class="notice">Loading...</div>
///
/// <!-- Loaded view -->
/// <template [ngIf]="item != null">
///   <item [item]="item"></item>
///   <div *ngIf="item['comments'].isEmpty">There are no comments yet.</div>
///   <comment
///       *ngFor="let comment of item['comments']"
///       [comment]="comment">
///   </comment>
/// </template>
/// ```
///
/// <?code-excerpt "packages/template_syntax/app_component.html (NgIf-1)"?>
/// ```html
/// <my-hero *ngIf="isActive"></my-hero>
/// ```
///
/// <?code-excerpt "packages/structural_directives/app_component.html (asterisk)"?>
/// ```html
/// <div *ngIf="hero != null" >{{hero.name}}</div>
/// ```
///
/// <?code-excerpt "packages/structural_directives/app_component.html (ngif-template)"?>
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
    if (!checkBinding(_prevCondition, newCondition)) {
      return;
    }
    if (newCondition) {
      _viewContainer.createEmbeddedView(_templateRef);
    } else {
      _viewContainer.clear();
    }
    _prevCondition = newCondition;
  }
}
