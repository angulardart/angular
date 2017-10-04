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
  T inject<T>(Object token) {
    final result = injectOptional(token);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    return result;
  }

  @override
  Object injectOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    var result = injectFromSelfOptional(token, orElse);
    if (identical(result, orElse)) {
      result = injectFromAncestryOptional(token, orElse);
    }
    return result;
  }

  /// Injects and returns an object representing [token] from this injector.
  ///
  /// Unlike [inject], this only checks this _itself_, not the parent or the
  /// ancestry of injectors. This is equivalent to constructor parameters
  /// annotated with `@Self`.
  ///
  /// Throws an error if [token] was not found.
  @protected
  T injectFromSelf<T>(Object token) {
    final result = injectFromSelfOptional(token);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    return result;
  }

  /// Injects and returns an object representing [token] from this injector.
  ///
  /// Unlike [inject], this only checks this _itself_, not the parent or the
  /// ancestry of injectors. This is equivalent to constructor parameters
  /// annotated with `@Self`.
  @protected
  Object injectFromSelfOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]);

  /// Injects and returns an object representing [token] from the parent.
  ///
  /// Unlike [inject], this only checks instances registered directly with the
  /// parent injector, not this injector, or further ancestors. This is
  /// equivalent to constructor parameters annotated with `@Host`.
  ///
  /// Throws an error if [token] was not found.
  @protected
  T injectFromParent<T>(Object token) {
    final result = injectFromParentOptional(token);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    return result;
  }

  /// Injects and returns an object representing [token] from the parent.
  ///
  /// Unlike [inject], this only checks instances registered directly with the
  /// parent injector, not this injector, or further ancestors. This is
  /// equivalent to constructor parameters annotated with `@Host`.
  @protected
  Object injectFromParentOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      parent.injectFromSelfOptional(token, orElse);

  /// Injects and returns an object representing [token] from ancestors.
  ///
  /// Unlike [inject], this only checks instances registered with any ancestry
  /// injector, not this injector. This is equivalent to the constructor
  /// parameters annotated with `@SkipSelf`.
  ///
  /// Throws an error if [token] was not found.
  @protected
  T injectFromAncestry<T>(Object token) {
    final result = injectFromAncestryOptional(token);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    return result;
  }

  /// Injects and returns an object representing [token] from ancestors.
  ///
  /// Unlike [inject], this only checks instances registered with any ancestry
  /// injector, not this injector. This is equivalent to the constructor
  /// parameters annotated with `@SkipSelf`.
  @protected
  Object injectFromAncestryOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) =>
      parent.injectOptional(token, orElse);
}
