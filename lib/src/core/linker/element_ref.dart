/// A wrapper around a native element inside of a View.
///
/// An `ElementRef` is backed by a render-specific element. In the browser, this
/// is usually a DOM element.
// Note: We don't expose things like `Injector`, `ViewContainer`, ... here, i.e.
// users have to ask for what they need. With that, we can build better analysis
// tools and could do better codegen in the future.
class ElementRef {
  /// The underlying native element.
  ///
  /// Use with caution: Use this API as the last resort when direct access to
  /// DOM is needed. Use templating and data-binding provided by Angular
  /// instead.
  final dynamic nativeElement;
  ElementRef(this.nativeElement);
}
