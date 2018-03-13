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
const Object throwIfNotFound = const Object();

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
    final result = injectOptional(token, notFoundValue);
    if (identical(result, throwIfNotFound)) {
      return throwsNotFound(this, token);
    }
    errors.debugInjectorLeave(token);
    return result;
  }

  /// Injects and returns an object representing [token].
  ///
  /// ```dart
  /// final rpcService = injector.inject<RpcService>();
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
  @experimental
  const factory GenerateInjector.fromModules(
    List<Module> modules,
  ) = GenerateInjector;
}
