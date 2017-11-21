/// A wrapper around a native element inside of a View.
///
/// An `ElementRef` is backed by a render-specific element. In the browser, this
/// is usually a DOM element.
// Note: We don't expose things like `Injector`, `ViewContainer`, ... here, i.e.
// users have to ask for what they need. With that, we can build better analysis
// tools and could do better codegen in the future.

/// A wrapper around a native DOM elemnt inside of a template.
///
/// **DEPRECATED**: See https://github.com/dart-lang/angular/issues/692.
@Deprecated('Inject Element or HtmlElement from dart:html instead.')
class ElementRef {
  /// The underlying native element.
  final dynamic nativeElement;

  const ElementRef(this.nativeElement);
}
