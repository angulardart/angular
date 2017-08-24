import 'package:meta/meta.dart';

import 'empty.dart';
import 'hierarchical.dart';
import 'map.dart';
import 'reflective.dart';

/// **INTERNAL ONLY**: Work in progress.
class InjectionToken<T> {}

/// **INTERNAL ONLY**: Placeholder until we support 1.25.0+ (function syntax).
@visibleForTesting
typedef T OrElseInject<T>(Injector injector, Object token);

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
@visibleForTesting
const Object throwIfNotFound = const Object();

@visibleForTesting
Null throwsNotFound(Injector injector, Object token) {
  throw new ArgumentError('No provider found for $token.');
}

/// Support for imperatively loading dependency injected services at runtime.
///
/// [Injector] is a simple interface that accepts a valid _token_ (often either
/// a `Type` or `OpaqueToken`, but can be a custom object that respects equality
/// based on identity), and returns an instance for that token.
abstract class Injector {
  @visibleForTesting
  const Injector();

  /// Creates an injector that has no providers.
  ///
  /// Can be used as the root injector in a hierarchy to form the default
  /// implementation (for provider not found).
  const factory Injector.empty([HierarchicalInjector parent]) = EmptyInjector;

  /// Create a new [Injector] that uses a basic [map] of token->instance.
  ///
  /// Optionally specify the [parent] injector.
  ///
  /// It is considered _unsupported_ to provide `null` or `Injector` as a key.
  const factory Injector.map(
    Map<Object, Object> providers, [
    HierarchicalInjector parent,
  ]) = MapInjector;

  /// Creates a new [Injector] that resolves `Provider` instances at runtime.
  ///
  /// **EXPERIMENTAL**: Not yet supported.
  ///
  /// This is an **expensive** operation without any sort of caching or
  /// optimizations that manually walks the nested [providersOrLists], and uses
  /// a form of runtime reflection to figure out how to map the providers to
  /// runnable code.
  ///
  /// Using this function can **disable all tree-shaking** for any `@Injectable`
  /// annotated function or class in your _entire_ transitive application, and
  /// is provided for legacy compatibility only.
  @experimental
  factory Injector.slowReflective(
    List<Object> providersOrLists, [
    HierarchicalInjector parent = const EmptyInjector(),
  ]) =>
      ReflectiveInjector.resolveAndCreate(providersOrLists, parent);

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
  dynamic get(Object token, [Object notFoundValue = throwIfNotFound]) {
    final OrElseInject orElse = identical(notFoundValue, throwIfNotFound)
        ? throwsNotFound
        : (_, __) => notFoundValue;
    return inject<dynamic>(token: token, orElse: orElse);
  }

  /// Injects and returns an object representing [token].
  ///
  /// ```dart
  /// final rpcService = injector.inject<RpcService>();
  /// ```
  ///
  /// _or_:
  ///
  /// ```dart
  ///
  /// ```
  ///
  /// **EXPERIMENTAL**: Reified types are currently not supported in all of the
  /// various Dart runtime implementations (only DDC, not Dart2JS or the VM), so
  /// [fallbackToken] is currently required to be used.
  @experimental
  @protected
  T inject<T>({
    @required Object token,
    OrElseInject<T> orElse: throwsNotFound,
  });
}
