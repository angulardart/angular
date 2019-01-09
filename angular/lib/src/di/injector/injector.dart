import 'package:angular/src/core/di/opaque_token.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

import '../errors.dart' as errors;
import '../module.dart';
import 'empty.dart';
import 'hierarchical.dart';
import 'map.dart';
import 'runtime.dart';

// TODO(matanl): Remove export after we have a 'runtime.dart' import.
export '../../core/di/opaque_token.dart' show MultiToken, OpaqueToken;

/// **INTERNAL ONLY**: Sentinel value for determining a missing DI instance.
const Object throwIfNotFound = Object();

/// **INTERNAL ONLY**: Throws "no provider found for {token}".
Null throwsNotFound(Injector injector, Object token) {
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
  /// It is considered _unsupported_ to provide `Injector` with `null` as either
  /// a key or a value, and assertion may be thrown in development mode.
  const factory Injector.map(
    Map<Object, Object> providers, [
    HierarchicalInjector parent,
  ]) = MapInjector;

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

  /// Injects and returns an object representing [token].
  ///
  /// If the key was not found, returns [orElse] (default is `null`).
  ///
  /// **NOTE**: This is an internal-only method and may be removed.
  @protected
  Object provideUntyped(Object token, [Object orElse]);

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

/// Annotates a method to generate an [Injector] factory at compile-time.
///
/// Using `@GenerateInjector` is conceptually similar to using `@Component` or
/// `@Directive` with a `providers: const [ ... ]` argument, or to creating a
/// an injector at runtime with [ReflectiveInjector], but like a component or
/// directive that injector is generated ahead of time, during compilation:
///
/// ```
/// import 'my_file.template.dart' as ng;
///
/// @GenerateInjector(const [
///   const Provider(A, useClass: APrime),
/// ])
/// // The generated factory is your method's name, suffixed with `$Injector`.
/// final InjectorFactory example = example$Injector;
/// ```
class GenerateInjector {
  // Used internally via analysis only.
  // ignore: unused_field
  final List<Object> _providersOrModules;

  const GenerateInjector(this._providersOrModules);

  /// Generate an [Injector] from [Module]s instead of untyped lists.
  const factory GenerateInjector.fromModules(
    List<Module> modules,
  ) = GenerateInjector;
}
