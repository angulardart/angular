import 'package:angular/src/runtime.dart';
import 'package:angular_compiler/v1/src/metadata.dart';
import 'package:meta/meta.dart';

import '../errors.dart' as errors;
import 'empty.dart';
import 'injector.dart';

/// Base type for the [Injector] interface with support for hierarchies.
///
/// Hierarchical injection is a popular pattern in AngularDart given that the
/// component tree naturally forms a tree structure of components (and
/// implicitly, injectors).
///
/// **NOTE**: This is not a user-visible class. In the past
/// [HierarchicalInjector] _extended_ [Injector] and relied on implicit
/// (and explicit) downcasts across the API surface. See b/130182015.
abstract class HierarchicalInjector {
  @protected
  final HierarchicalInjector parent;

  @visibleForTesting
  const HierarchicalInjector([HierarchicalInjector parent])
      : parent = parent ?? const Injector.empty();

  /// **INTERNAL ONLY**: Used to implement [EmptyInjector] efficiently.
  const HierarchicalInjector.maybeEmpty([this.parent]);

  /// Injects and returns an object representing [token].
  ///
  /// If the key was not found, returns [orElse] (default is `null`).
  ///
  /// **NOTE**: This is an internal-only method and may be removed.
  @protected
  Object provideUntyped(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    errors.debugInjectorEnter(token);
    var result = injectFromSelfOptional(token, orElse);
    if (identical(result, orElse)) {
      result = injectFromAncestryOptional(token, orElse);
    }
    errors.debugInjectorLeave(token);
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
    return unsafeCast<T>(result);
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
    return unsafeCast<T>(result);
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
    return unsafeCast<T>(result);
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
      parent.provideUntyped(token, orElse);

  /// Returns an instance from the injector based on the provided [token].
  ///
  /// ```
  /// HeroService heroService = injector.get(HeroService);
  /// ```
  ///
  /// If not found, either:
  /// - Returns [notFoundValue] if set to a non-default value.
  /// - Throws an error (default behavior).
  ///
  /// An injector always returns itself if [Injector] is given as a token.
  @mustCallSuper
  dynamic get(Object token, [Object notFoundValue = throwIfNotFound]) {
    errors.debugInjectorEnter(token);
    final result = provideUntyped(token, notFoundValue);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    errors.debugInjectorLeave(token);
    return result;
  }

  /// Finds and returns an object instance provided for a type [token].
  ///
  /// A runtime assertion is thrown in debug mode if:
  ///
  /// * [T] is explicitly or implicitly bound to `dynamic`.
  /// * If [T] is not `Object`, the DI [token] is not the *same* as [T].
  ///
  /// An error is thrown if a provider is not found.
  T provideType<T extends Object>(Type token) {
    // NOTE: It is not possible to design this API in such a way that only "T"
    // can be used, and not require "token" as well. Our injection system
    // currently uses "identical" (similar to JS' ===), and the types passed
    // through "T" are not canonical (they are == equivalent, but not ===).
    //
    // See historic discussion here: dartbug.com/35098
    assert(T != dynamic, 'Returning a dynamic is not supported');
    return unsafeCast(get(token));
  }

  /// Finds and returns an object instance provided for a type [token].
  ///
  /// Unlike [provideType], `null` is returned if a provider is not found.
  ///
  /// A runtime assertion is thrown in debug mode if:
  ///
  /// * [T] is explicitly or implicitly bound to `dynamic`.
  /// * If [T] is not `Object`, the DI [token] is not the *same* as [T].
  T provideTypeOptional<T extends Object>(Type token) {
    // See provideType.
    assert(T != dynamic, 'Returning a dynamic is not supported');
    return unsafeCast(get(token, null));
  }

  /// Finds and returns an object instance provided for a [token].
  ///
  /// An error is thrown if a provider is not found.
  T provideToken<T>(OpaqueToken<T> token) {
    return unsafeCast(get(token));
  }

  /// Finds and returns an object instance provided for a [token].
  ///
  /// Unlike [provideToken], `null` is returned if a provider is not found.
  T provideTokenOptional<T>(OpaqueToken<T> token) {
    return unsafeCast(get(token, null));
  }
}
