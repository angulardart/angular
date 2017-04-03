class CompilerConfig {
  /// [true] if compiler is generating development binary.
  final bool genDebugInfo;

  /// If [true], generates code to show binding values inside live DOM for
  /// debugging.
  final bool logBindingUpdate;

  /// If [true], shadow host selectors prevent following selectors from being
  /// scoped to their component much like a shadow piercing combinator. It
  /// also allows the use of the following deprecated selectors:
  /// * ::content
  /// * ::shadow
  /// * polyfill-next-selector
  /// * polyfill-unscoped-rule
  final bool useLegacyStyleEncapsulation;

  CompilerConfig({
    this.genDebugInfo: false,
    this.logBindingUpdate: false,
    this.useLegacyStyleEncapsulation: false,
  });
}
