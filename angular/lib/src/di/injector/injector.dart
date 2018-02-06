import 'package:meta/meta.dart';

import 'empty.dart';
import 'hierarchical.dart';
import 'map.dart';
import 'runtime.dart';

// TODO(matanl): Remove export after we have a 'runtime.dart' import.
export '../../core/di/opaque_token.dart' show MultiToken, OpaqueToken;

/// **INTERNAL ONLY**: Work in progress.
class InjectionToken<T> {}

/// **INTERNAL ONLY**: Placeholder until we support 1.25.0+ (function syntax).
typedef T OrElseInject<T>(Injector injector, Object token);

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
const Object throwIfNotFound = const Object();

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

  /// An _annotation_ used to generate an [Injector] at compile-time.
  ///
  /// **EXPERIMENTAL**: Not yet supported.
  ///
  /// Example use:
  /// ```
  /// @Injector.generate(const [
  ///   const Provider(A, useClass: APrime),
  /// ])
  /// Injector fooInjector([HierarchicalInjector parent]) {
  ///   return fooInjector$Generated(parent);
  /// }
  /// ```
  ///
  /// It is a **runtime error** to use the resulting [Injector] object, so make
  /// sure to _only_ use `@Injector.generate` as an annotation on a top-level
  /// or static method.
  @experimental
  const factory Injector.generate(List<Object> providers) = _GenerateInjector;

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
    final result = injectOptional(token, notFoundValue);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    return result;
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
  T inject<T>(Object token);

  /// Injects and returns an object representing [token].
  ///
  /// If the key was not found, returns [orElse] (default is `null`).
  Object injectOptional(Object token, [Object orElse]);
}

/// Used as a compiler-only base class for inheritance.
abstract class GeneratedInjector extends HierarchicalInjector {
  GeneratedInjector([Injector parent]) : super(parent ?? const EmptyInjector());
}

// Used as a token-type for the AngularDart compiler.
class _GenerateInjector implements Injector {
  final List<Object> providersOrModules;

  const _GenerateInjector(this.providersOrModules);

  @override
  get(Object token, [Object notFoundValue = throwIfNotFound]) {
    throw new UnsupportedError('Not a runtime class.');
  }

  @override
  T inject<T>(Object token) {
    throw new UnsupportedError('Not a runtime class.');
  }

  @override
  injectOptional(Object token, [Object orElse]) {
    throw new UnsupportedError('Not a runtime class.');
  }
}
