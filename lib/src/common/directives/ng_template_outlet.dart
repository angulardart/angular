import "package:angular2/core.dart";
import 'package:angular2/src/core/linker/view_ref.dart';

/// Creates and inserts an embedded view based on a prepared `TemplateRef`.
/// You can attach a context object to the `EmbeddedViewRef` by setting `[ngOutletContext]`.
/// `[ngOutletContext]` should be an object, the object's keys will be the local template variables
/// available within the `TemplateRef`.
///
/// Note: using the key `$implicit` in the context object will set it's value as default.
///
/// ### Syntax
///
/// ```
/// <template [ngTemplateOutlet]="templateRefExpression"
///           [ngOutletContext]="objectExpression">
/// </template>
/// ```
///
/// @experimental
@Directive(selector: "[ngTemplateOutlet]")
class NgTemplateOutlet implements OnChanges {
  EmbeddedViewRef _viewRef;
  var _context;
  TemplateRef _templateRef;
  ViewContainerRef _viewContainerRef;

  NgTemplateOutlet(this._viewContainerRef);

  @Input()
  set ngOutletContext(context) => _context = context;

  @Input()
  set ngTemplateOutlet(TemplateRef templateRef) => _templateRef = templateRef;

  @override
  ngOnChanges(Map<String, SimpleChange> changes) {
    if (_viewRef != null) {
      _viewContainerRef.remove(_viewContainerRef.indexOf(_viewRef));
    }

    if (_templateRef != null) {
      _viewRef = _viewContainerRef.createEmbeddedView(_templateRef, _context);
    }
  }
}
