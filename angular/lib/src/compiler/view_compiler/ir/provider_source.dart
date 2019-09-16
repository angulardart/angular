import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/output/output_ast.dart' as o;

/// Provider interface passed to view compiler backends to generate code
/// to instantiate a provider and consume.
///
/// This allows us to hide the hierarchical nature of provider lookups and
/// the actual resolution from view compiler backend.
abstract class ProviderSource {
  final CompileTokenMetadata token;

  ProviderSource(this.token);

  /// Returns a reference to this provider instance.
  o.Expression build();

  /// Returns a reference to this provider's `ChangeDetectorRef`, if necessary.
  ///
  /// Returns a non-null result only if this provider instance is a component
  /// that uses `ChangeDetectionStrategy.OnPush`. This result is used to
  /// implement `ChangeDetectorRef.markChildForCheck()`.
  ///
  /// Returns null otherwise.
  o.Expression buildChangeDetectorRef() => null;

  /// Whether a dynamic `injectorGet(...)` is required to resolve this provider.
  ///
  /// For example:
  /// ```dart
  ///   // DependencyService is dynamically required to resolve MyService.
  ///   _MyService = MyService(injectorGet(DependencyService));
  /// ```
  bool get hasDynamicDependencies => false;
}
