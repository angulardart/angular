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

  GeneratorOptions(
      {this.reflectPropertiesAsAttributes: false, this.codegenMode: ''});
}
