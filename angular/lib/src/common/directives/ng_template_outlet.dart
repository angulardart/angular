import 'package:angular/core.dart' show Directive, DoCheck, Input;
import 'package:angular/src/core/linker.dart'
    show EmbeddedViewRef, TemplateRef, ViewContainerRef;

/// Inserts an embedded view, created from a [TemplateRef].
///
/// ### Examples
///
/// ```dart
/// @Component(
///   selector: 'example',
///   template: '''
///     <template #text let-text>
///       <span>{{text}}</span>
///     </template>
///     <template #icon let-iconUrl let-width="w" let-height="h">
///       <img src="{{iconUrl}}" width="{{width}}" height="{{height}}">
///     </template>
///
///     <template
///         [ngTemplateOutlet]="text"
///         [ngTemplateOutletContext]="textContext">
///     </template>
///     <template
///         [ngTemplateOutlet]="icon">
///         [ngTemplateOutletContext]="iconContext">
///     </template>
///   ''',
///   directives: const [NgTemplateOutlet],
/// )
/// class ExampleComponent {
///   Map<String, dynamic> textContext = {
///     '\$implicit': 'Hello world!',
///   };
///
///   Map<String, dynamic> iconContext = {
///     '\$implicit': 'icon.png',
///     'w': '16',
///     'h': '16',
///   };
/// }
/// ```
@Directive(
  selector: '[ngTemplateOutlet]',
)
class NgTemplateOutlet implements DoCheck {
  final ViewContainerRef _viewContainerRef;

  Map<String, dynamic> _context;
  EmbeddedViewRef _insertedViewRef;

  NgTemplateOutlet(this._viewContainerRef);

  /// The [TemplateRef] used to create the embedded view.
  ///
  /// Any previously embedded view is removed when [templateRef] changes. If
  /// [templateRef] is null, no embedded view is inserted.
  @Input()
  set ngTemplateOutlet(TemplateRef templateRef) {
    if (_insertedViewRef != null) {
      _viewContainerRef.remove(_viewContainerRef.indexOf(_insertedViewRef));
    }
    if (templateRef != null) {
      _insertedViewRef = _viewContainerRef.createEmbeddedView(templateRef);
    }
  }

  /// An optional map of local variables to define in the embedded view.
  ///
  /// Theses variables can be assigned to template input variables declared
  /// using 'let-' bindings. The variable '$implicit' can be used to set the
  /// default value of any 'let-' binding without an explicit assignment.
  @Input()
  set ngTemplateOutletContext(Map<String, dynamic> context) {
    _context = context;
  }

  @override
  void ngDoCheck() {
    if (_context == null || _insertedViewRef == null) return;
    // Local variables are deliberately set every change detection cycle to
    // simplify the design. It's unlikely this is worse than conditionally
    // setting them based on whether they actually changed, since their values
    // are change detected again wherever they're bound.
    _context.forEach(_insertedViewRef.setLocal);
  }
}
