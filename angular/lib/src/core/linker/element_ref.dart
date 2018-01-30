/// A wrapper around a native element inside of a View.
///
/// An `ElementRef` is backed by a render-specific element. In the browser, this
/// is usually a DOM element.

/// **DEPRECATED**: A wrapper around a native DOM element inside of a View.
///
/// Inject `Element` or `HtmlElement` from `dart:html` instead; this will be
/// removed in a future version of AngularDart, and has unnecessary overhead.
@Deprecated('Inject or reference dart:html Element or HtmlElement instead')
class ElementRef {
  final dynamic nativeElement;
  const ElementRef(this.nativeElement);
}
