import 'package:meta/meta.dart';

import '../errors.dart' as errors;
import 'empty.dart';
import 'hierarchical.dart';
import 'map.dart';

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
const Object throwIfNotFound = Object();

/// **INTERNAL ONLY**: Throws "no provider found for {token}".
Null throwsNotFound(HierarchicalInjector injector, Object token) {
  throw errors.noProviderError(token);
}

/// Defines a function that creates an injector around a [parent] injector.
///
/// An [InjectorFactory] can be as simple as a closure or function:
/// ```dart
/// class Example {}
///
/// /// Returns an [Injector] that provides an `Example` service.
/// Injector createInjector([Injector parent]) {
///   return new Injector.map({
///     Example: new Example(),
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
typedef InjectorFactory = Injector Function([Injector parent]);

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
abstract class Injector implements HierarchicalInjector {
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
  /// It is considered _unsupported_ to provide `Injector` with `null` as either
  /// a key or a value, and assertion may be thrown in development mode.
  const factory Injector.map(
    Map<Object, Object> providers, [
    HierarchicalInjector parent,
  ]) = MapInjector;
}
