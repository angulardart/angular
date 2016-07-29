import 'package:angular2/core.dart'
    show Directive, ViewContainerRef, TemplateRef;

/// Causes the element and its contents to appear in the DOM conditionally.
///
/// The condition is supplied as a boolean template expression. When the
/// condition changes, the UI is updated automatically.
///
/// **Example**:
///
///   <!-- Place directly on a DOM element -->
///   <div *ngIf="shouldShowError">An occur occurred</div>
///
///   <!-- Or use the template tag -->
///   <template [ngIf]="shouldShowError">
///     <div>An error ocurred</div>
///   </template>
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
