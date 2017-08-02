import 'package:meta/meta.dart';

// This file is transitional.
//
// Currently the Injector class in "src/core/di/injector.dart" is the one still
// used in production, and this one is slightly speculative based on a new more
// static interface for DI.
//
// Remaining work:
// - [ ] Make ElementInjector implement {this}Injector
// - [ ] Make ReflectiveInjector implement {this}Injector

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
@visibleForTesting
const THROW_IF_NOT_FOUND = const Object();

// @alwaysThrows
T _throwsNotFound<T>(Injector injector, Object token) {
  throw new ArgumentError('No provider found for $token.');
}

// TODO: Use the new function syntax after 1.24.0.
@visibleForTesting
typedef T OrElseInject<T>(Injector injector, Object token);

/// Support for imperatively loading dependency injected services.
abstract class Injector {
  final Injector _parent;

  @visibleForTesting
  const Injector([this._parent]);

  /// Creates an injector that has no providers.
  ///
  /// Can be used as the root injector in a hierarchy to form the default
  /// implementation (for provider not found).
  const factory Injector.empty([Injector parent]) = _EmptyInjector;

  /// Create a new [Injector] that uses a basic [map] of token->instance.
  ///
  /// Optionally specify the [parent] injector.
  ///
  /// It is considered _unsupported_ to provide `null` or `Injector` as a key.
  const factory Injector.map(
    Map<Object, Object> providers, [
    Injector parent,
  ]) = _MapInjector;

  /// Returns an instance from the injector based on the provided [token].
  ///
  /// ```
  /// HeroService heroService = injector.get(HeroService);
  /// ```
  ///
  /// If not found, either:
  /// * Returns [notFoundValue] if set to a non-default value.
  /// * Throws a [NoProviderError].
  ///
  /// An injector always returns itself if [Injector] is given as a [token].
  dynamic get(Object token, [Object notFoundValue = THROW_IF_NOT_FOUND]) {
    final orElse = identical(notFoundValue, THROW_IF_NOT_FOUND)
        ? _throwsNotFound
        : (_, __) => notFoundValue;
    return inject(token, orElse: orElse);
  }

  /// Injects and returns an object representing [token].
  ///
  /// ```dart
  /// final rpcService = injector.inject(RpcService);
  /// ```
  T inject<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      injectFromSelf<T>(
        token,
        orElse: (_, token) => injectFromAncestry(
              token,
              orElse: (_, token) => orElse(this, token),
            ),
      );

  /// Injects and returns an object representing [token] from this injector.
  ///
  /// Unlike [inject], this only checks this _itself_, not the parent or the
  /// ancestry of injectors. This is equivalent to constructor parameters
  /// annotated with `@Self`.
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  });

  /// Injects and returns an object representing [token] from the parent.
  ///
  /// Unlike [inject], this only checks instances registered directly with the
  /// parent injector, not this injector, or further ancestors. This is
  /// equivalent to constructor parameters annotated with `@Host`.
  T injectFromParent<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      _parent.injectFromSelf<T>(
        token,
        orElse: (_, token) => orElse(this, token),
      );

  /// Injects and returns an object representing [token] from ancestors.
  ///
  /// Unlike [inject], this only checks instances registered with any ancestry
  /// injector, not this injector. This is equivalent to the constructor
  /// parameters annotated with `@SkipSelf`.
  T injectFromAncestry<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      _parent.inject<T>(
        token,
        orElse: (_, token) => orElse(this, token),
      );
}

class _EmptyInjector extends Injector {
  const _EmptyInjector([Injector parent]) : super(parent);

  @override
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      identical(token, Injector) ? this : orElse(this, token);

  @override
  T injectFromParent<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      _parent?.injectFromSelf(token, orElse: orElse) ?? orElse(this, token);

  @override
  T injectFromAncestry<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      _parent?.inject(token, orElse: orElse) ?? orElse(this, token);
}

class _MapInjector extends Injector {
  final Map<Object, Object> _providers;

  const _MapInjector(
    this._providers, [
    Injector parent = const Injector.empty(),
  ])
      : super(parent);

  @override
  T injectFromSelf<T>(
    Object token, {
    OrElseInject<T> orElse: _throwsNotFound,
  }) =>
      _providers[token] ??
      (identical(token, Injector) ? this : orElse(this, token));
}
