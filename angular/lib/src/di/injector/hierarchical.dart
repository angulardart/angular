import 'package:meta/meta.dart';

import 'empty.dart';
import 'injector.dart';

/// Implements the [Injector] interface with support for hierarchical injection.
///
/// Hierarchical injection is a popular pattern in AngularDart given that the
/// component tree naturally forms a tree structure of components (and
/// implicitly, injectors).
abstract class HierarchicalInjector extends Injector {
  @protected
  final HierarchicalInjector parent;

  @visibleForTesting
  const HierarchicalInjector([this.parent = const EmptyInjector()]);

  /// **INTERNAL ONLY**: Used to implement [EmptyInjector] efficiently.
  @visibleForTesting
  const HierarchicalInjector.maybeEmpty([this.parent]);

  @override
  T inject<T>({
    @required Object token,
    OrElseInject<T> orElse: throwsNotFound,
  }) {
    return injectFromSelf(
      token,
      orElse: (_, token) {
        return injectFromAncestry(
          token,
          orElse: (_, token) => orElse(this, token),
        );
      },
    );
  }

  /// Injects and returns an object representing [token] from this injector.
  ///
  /// Unlike [inject], this only checks this _itself_, not the parent or the
  /// ancestry of injectors. This is equivalent to constructor parameters
  /// annotated with `@Self`.
  @protected
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  });

  /// Injects and returns an object representing [token] from the parent.
  ///
  /// Unlike [inject], this only checks instances registered directly with the
  /// parent injector, not this injector, or further ancestors. This is
  /// equivalent to constructor parameters annotated with `@Host`.
  @protected
  T injectFromParent<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      parent.injectFromSelf(
        token,
        orElse: (_, token) => orElse(this, token),
      );

  /// Injects and returns an object representing [token] from ancestors.
  ///
  /// Unlike [inject], this only checks instances registered with any ancestry
  /// injector, not this injector. This is equivalent to the constructor
  /// parameters annotated with `@SkipSelf`.
  @protected
  T injectFromAncestry<T>(
    Object token, {
    OrElseInject<T> orElse: throwsNotFound,
  }) =>
      parent.inject(
        token: token,
        orElse: (_, token) => orElse(this, token),
      );
}
