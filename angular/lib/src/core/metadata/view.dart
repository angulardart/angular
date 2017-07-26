/// Defines template and style encapsulation options available for Component's
/// [View].
///
/// See [View#encapsulation].
enum ViewEncapsulation {
  /// Emulate `Native` scoping of styles by adding an attribute containing
  /// surrogate id to the Host Element and pre-processing the style rules
  /// provided via [View#styles] or [View#stylesUrls], and
  /// adding the new Host Element attribute to all selectors.
  ///
  /// This is the default option.
  Emulated,

  /// Don't provide any template or style encapsulation.
  None
}
