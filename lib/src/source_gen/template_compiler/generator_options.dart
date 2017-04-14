/// Configuration options for the Angular2 codegen generator.
class GeneratorOptions {
  /// Whether to reflect property values as attributes.
  ///
  /// If this is `true`, the change detection code will echo set property values
  /// as attributes on DOM elements, which may aid in application debugging.
  final bool reflectPropertiesAsAttributes;

  /// Whether to generate debug information in views.
  ///
  /// Needed for testing and improves error messages when exception are
  /// triggered.
  final String codegenMode;

  /// Whether to use legacy CSS style encapsulation selectors and behavior.
  ///
  /// When [true], shadow host selectors prevent following selectors from being
  /// scoped to their component much like a shadow piercing combinator. It
  /// also allows the use of the following deprecated selectors:
  /// * ::content
  /// * ::shadow
  /// * polyfill-next-selector
  /// * polyfill-unscoped-rule
  final bool useLegacyStyleEncapsulation;

  /// Wheter to use the global set of visible assets instead of
  /// buildStep.hasInput().
  ///
  /// For bazel workspaces, this should be [true] (default), since
  /// buildStep.hasInput() doesn't work in all cases. In other workspaces, like
  /// with build_runner, this should be [false].
  final bool collectAssets;

  GeneratorOptions({
    this.reflectPropertiesAsAttributes: false,
    this.codegenMode: '',
    this.useLegacyStyleEncapsulation: false,
    this.collectAssets: true,
  });
}
