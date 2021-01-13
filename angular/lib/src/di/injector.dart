import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:angular/src/meta.dart';
import 'package:angular/src/utilities.dart';

import 'errors.dart' as errors;

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
const Object throwIfNotFound = Object();

/// **INTERNAL ONLY**: Throws "no provider found for {token}".
Never throwsNotFound(HierarchicalInjector injector, Object token) {
  throw errors.noProviderError(token);
}

/// Defines a function that creates an injector around a [parent] injector.
///
/// An [InjectorFactory] can be as simple as a closure or function:
/// ```dart
/// class Example {}
///
/// /// Returns an [Injector] that provides an `Example` service.
/// Injector createInjector(Injector parent) {
///   return Injector.map({
///     Example: Example(),
///   }, parent);
/// }
///
/// void main() {
///   var injector = createInjector();
///   print(injector.get(Example)); // 'Instance of Example'.
/// }
/// ```
///
/// You may also _generate_ an [InjectorFactory] using [GenerateInjector].
typedef InjectorFactory = Injector Function(Injector parent);

/// Support for imperatively loading dependency injected services at runtime.
///
/// [Injector] is a simple interface that accepts a valid _token_ (often either
/// a `Type` or `OpaqueToken`, but can be a custom object that respects equality
/// based on identity), and returns an instance for that token.
///
/// **WARNING**: It is not supported to sub-class this type in your own
/// applications. There are hidden contracts that are not implementable by
/// client code. If you need a _mock-like_ implementation of [Injector] instead
/// prefer using [Injector.map].
abstract class Injector {
  @visibleForTesting
  const Injector();

  /// Creates an injector that has no providers.
  ///
  /// Can be used as the root injector in a hierarchy to form the default
  /// implementation (for provider not found).
  const factory Injector.empty() = _EmptyInjector;

  /// Create a new [Injector] that uses a basic [map] of token->instance.
  ///
  /// The map instance is copied (not referenced) into `HashMap.identity`.
  ///
  /// Optionally specify the [parent] injector.
  ///
  /// It is considered _unsupported_ to provide `Injector` as a key or `null`
  /// as either a key or a value, and assertion may be thrown in development
  /// mode.
  factory Injector.map(
    Map<Object, Object> providers, [
    Injector parent,
  ]) = _MapInjector;

  /// Injects and returns an object representing [token].
  ///
  /// If the key was not found, returns [orElse] (default is `null`).
  ///
  /// **NOTE**: This is an internal-only method and may be removed.
  @protected
  T provideUntyped<T>(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    errors.debugInjectorEnter(token);
    var result = injectFromSelfOptional(token, orElse);
    if (identical(result, orElse)) {
      result = injectFromAncestryOptional(token, orElse);
    }
    errors.debugInjectorLeave(token);
    return unsafeCast(result);
  }

  /// Injects and returns an object representing [token] from this injector.
  ///
  /// Unlike [inject], this only checks this _itself_, not the parent or the
  /// ancestry of injectors. This is equivalent to constructor parameters
  /// annotated with `@Self`.
  ///
  /// Throws an error if [token] was not found.
  @protected
  @nonVirtual
  T injectFromSelf<T>(Object token) {
    final result = injectFromSelfOptional(token);
    if (identical(result, throwIfNotFound)) {
      throw errors.noProviderError(token);
    }
    return unsafeCast<T>(result);
  }

  /// Injects and returns an object representing [token] from this injector.
  ///
  /// Unlike [inject], this only checks this _itself_, not the parent or the
  /// ancestry of injectors. This is equivalent to constructor parameters
  /// annotated with `@Self`.
  @protected
  Object? injectFromSelfOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]);

  /// Injects and returns an object representing [token] from the parent.
  ///
  /// Unlike [inject], this only checks instances registered directly with the
  /// parent injector, not this injector, or further ancestors. This is
  /// equivalent to constructor parameters annotated with `@Host`.
  ///
  /// Throws an error if [token] was not found.
  @protected
  @nonVirtual
  T injectFromParent<T>(Object token) {
    final result = injectFromParentOptional(token);
    if (identical(result, throwIfNotFound)) {
      throw errors.noProviderError(token);
    }
    return unsafeCast(result);
  }

  /// Injects and returns an object representing [token] from the parent.
  ///
  /// Unlike [inject], this only checks instances registered directly with the
  /// parent injector, not this injector, or further ancestors. This is
  /// equivalent to constructor parameters annotated with `@Host`.
  @protected
  Object? injectFromParentOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]);

  /// Injects and returns an object representing [token] from ancestors.
  ///
  /// Unlike [inject], this only checks instances registered with any ancestry
  /// injector, not this injector. This is equivalent to the constructor
  /// parameters annotated with `@SkipSelf`.
  ///
  /// Throws an error if [token] was not found.
  @protected
  @nonVirtual
  T injectFromAncestry<T>(Object token) {
    final result = injectFromAncestryOptional(token);
    if (identical(result, throwIfNotFound)) {
      throw errors.noProviderError(token);
    }
    return unsafeCast(result);
  }

  /// Injects and returns an object representing [token] from ancestors.
  ///
  /// Unlike [inject], this only checks instances registered with any ancestry
  /// injector, not this injector. This is equivalent to the constructor
  /// parameters annotated with `@SkipSelf`.
  @protected
  Object? injectFromAncestryOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]);

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
  dynamic get(
    Object token, [
    Object? notFoundValue = throwIfNotFound,
  ]) {
    errors.debugInjectorEnter(token);
    final result = provideUntyped(token, notFoundValue);
    if (identical(result, throwIfNotFound)) {
      throw errors.noProviderError(token);
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
  @nonVirtual
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
  @nonVirtual
  T? provideTypeOptional<T extends Object>(Type token) {
    // See provideType.
    assert(T != dynamic, 'Returning a dynamic is not supported');
    return unsafeCast(get(token, null));
  }

  /// Finds and returns an object instance provided for a [token].
  ///
  /// An error is thrown if a provider is not found.
  ///
  /// **NOTE**: The `List<T>` returned by dependency injection is _not_
  /// guaranteed to be identical across invocations - that is, a new `List`
  /// instance is created every time a provider backed by a [MultiToken] is
  /// used:
  ///
  /// ```
  /// const usPresidents = MultiToken<String>('usPresidents');
  ///
  /// void example(Injector i) {
  ///   final a = i.provideToken(usPresidents);
  ///   final b = i.provideToken(usPresidents);
  ///   print(identical(a, b)); // false
  /// }
  /// ```
  @nonVirtual
  T provideToken<T extends Object>(OpaqueToken<T> token) {
    return unsafeCast(get(token));
  }

  /// Finds and returns an object instance provided for a [token].
  ///
  /// Unlike [provideToken], `null` is returned if a provider is not found.
  ///
  /// **NOTE**: The `List<T>` returned by dependency injection is _not_
  /// guaranteed to be identical across invocations - that is, a new `List`
  /// instance is created every time a provider backed by a [MultiToken] is
  /// used:
  ///
  /// ```
  /// const usPresidents = MultiToken<String>('usPresidents');
  ///
  /// void example(Injector i) {
  ///   final a = i.provideToken(usPresidents);
  ///   final b = i.provideToken(usPresidents);
  ///   print(identical(a, b)); // false
  /// }
  /// ```
  @nonVirtual
  T? provideTokenOptional<T extends Object>(OpaqueToken<T> token) {
    return unsafeCast(get(token, null));
  }
}

/// Base type for the [Injector] interface with explicit support for a parent.
///
/// Hierarchical injection is a popular pattern in AngularDart given that the
/// component tree naturally forms a tree structure of components (and
/// implicitly, injectors).
///
/// What differentiates [HierarchicalInjector] from [Injector] is that
/// implementations need only to implement [injectFromSelfOptional] to get a
/// fully working injector.
abstract class HierarchicalInjector extends Injector {
  final Injector _parent;

  @visibleForTemplate
  const HierarchicalInjector([Injector? parent])
      : _parent = parent ?? const _EmptyInjector();

  @override
  Object? injectFromAncestryOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    return _parent.provideUntyped(token, orElse);
  }

  @override
  Object? injectFromParentOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    return _parent.injectFromSelfOptional(token, orElse);
  }
}

/// Implements a simple injector that always throws.
class _EmptyInjector extends Injector {
  const _EmptyInjector();

  @override
  Object? injectFromSelfOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) =>
      identical(token, Injector) ? this : orElse;

  @override
  Object? injectFromParentOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    return orElse;
  }

  @override
  Object? injectFromAncestryOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    return orElse;
  }
}

/// Implements a simple injector backed by a [Map] of predefined values.
@Immutable()
class _MapInjector extends HierarchicalInjector implements Injector {
  final Map<Object, Object> _providers;

  _MapInjector(
    Map<Object, Object> providers, [
    Injector? parent,
  ])  : _providers = HashMap.identity()..addAll(providers),
        super(parent) {
    assert(!providers.containsKey(Injector));
  }

  @override
  Object? injectFromSelfOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    var result = _providers[token];
    if (result == null) {
      assert(
        !_providers.containsKey(token),
        'Value for $token should not be null for Injector.map',
      );
      result = identical(token, Injector) ? this : orElse;
    }
    return result;
  }
}
