import 'package:meta/meta.dart';

// TODO: Change `const Object()` -> `class _NotFound {}`.
//
// Other parts of Angular might rely on `const Object()` today, so this change
// could not be made cleanly yet.

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
@visibleForTesting
const THROW_IF_NOT_FOUND = const Object();

/// Base class for dynamic dependency injection via the [get] method.
abstract class Injector {
  /// An injector that always throws if [get] `notFoundValue` is not set.
  ///
  /// Can be used as the root injector in a hierarchy to form the default
  /// implementation (for provider not found).
  const factory Injector.empty() = _EmptyInjector;

  /// Create a new [Injector] that uses a basic [map] of token->instance.
  ///
  /// Optionally specify the [parent] injector.
  ///
  /// It is considered _unsupported_ to provide `null` or [Injector] as a key.
  factory Injector.map([
    Map map,
    Injector parent,
  ]) =>
      new MapInjector(parent, map);

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
  get(token, [notFoundValue = THROW_IF_NOT_FOUND]);
}

/// Always throws or returns a default value for [get].
class _EmptyInjector implements Injector {
  const _EmptyInjector();

  @override
  get(token, [notFoundValue = THROW_IF_NOT_FOUND]) {
    if (identical(token, Injector)) {
      return this;
    }
    if (identical(notFoundValue, THROW_IF_NOT_FOUND)) {
      throw new MissingProviderError(token);
    }
    return notFoundValue;
  }
}

/// A simple [Injector] implementation based on a [Map] of token->instance.
///
/// **DEPRECATED**: Use `Injector.map` instead.
@Deprecated('Use Injector.map` instead')
class MapInjector implements Injector {
  final Map<dynamic, dynamic> _map;
  final Injector _parent;

  // TODO: Make this const and use `this.` after no invocations pass null.
  @Deprecated('Use new Injector.map` instead')
  MapInjector([
    Injector parent,
    Map map,
  ])
      : _map = map ?? const {},
        _parent = parent ?? const Injector.empty();

  @override
  get(token, [notFoundValue = THROW_IF_NOT_FOUND]) =>
      _map[token] ??
      (identical(token, Injector) ? this : _parent.get(token, notFoundValue));
}

/// Thrown when [token] was requested but no instance was found.
class MissingProviderError extends Error {
  final token;

  MissingProviderError(this.token);

  @override
  String toString() => 'No provider found for $token.';
}
