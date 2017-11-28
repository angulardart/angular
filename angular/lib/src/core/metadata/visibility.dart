/// Restricts where a directive is visible for injection.
enum Visibility {
  /// Deprecated, renamed to [local].
  none,

  /// Can only be provided locally for injection via another token.
  ///
  /// Prevents the directive from automatically being provided for injection to
  /// its children.
  ///
  /// ```dart
  /// @Component(
  ///   ...,
  ///   providers: const [
  ///     const Provider(PublicDependency, useExisting: PrivateImplementation),
  ///   ],
  ///   visibility: Visibility.local,
  /// )
  /// class PrivateImplementation extends PublicDependency {}
  /// ```
  ///
  /// In this example, `PrivateImplementation` can't be injected directly, but
  /// it will be provided to satisfy a dependency on `PublicDependency`.
  local,
}
