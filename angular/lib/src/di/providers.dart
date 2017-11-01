// This file is transitional and not yet in use.
//
// See `provider.dart` for the current implementation.

import 'package:meta/meta.dart';

import '../core/di/opaque_token.dart';

/// A marker that represents a lack-of-value for the `useValue` parameter.
@visibleForTesting
const Object noValueProvided = '__noValueProvided__';

/// Describes at compile-time how an `Injector` should be configured.
///
/// Loosely put, a [Provider] is a binding between a _token_ (commonly either
/// a [Type] or [OpaqueToken]), and an implementation that is provided either by
/// invoking a constructor, a factory function, or referring to a literal value.
///
/// **NOTE**: The fields in this class are _soft deprecated_, and should not be
/// inspected or accessed at runtime. Future implementations may optimize by
/// removing them entirely.
@optionalTypeArgs
abstract class Provider<T> {
  /// Key used for injection, commonly a [Type] or [OpaqueToken].
  final Object token;

  /// Class whose constructor should be invoked when [token] is injected.
  ///
  /// When omitted and [token] is a [Type], this value is implicitly [token]:
  /// ```dart
  /// // The same thing.
  /// const Provider(Foo);
  /// const Provider(Foo, useClass: Foo);
  /// ```
  final Type useClass;

  /// Constant value to use when [token] is injected.
  ///
  /// It is recommended to use [useValue] with an [OpaqueToken] as [token]:
  /// ```dart
  /// const animationDelay = const OpaqueToken('animationDelay');
  ///
  /// const Provider(animationDelay, useValue: const Duration(seconds: 1));
  /// ```
  ///
  /// **NOTE**: The AngularDart compiler has limited heuristics for supporting
  /// complex nested objects beyond simple literals. If you encounter problems
  /// it is recommended to use [useFactory] instead.
  final Object useValue;

  /// An existing token to redirect to when [token] is injected.
  ///
  /// Commonly used for deprecation strategies or to-export an interface.
  final Object useExisting;

  /// A factory function to invoke when [token] is injected.
  ///
  /// For static forms of injection (i.e. compile-time), the [deps] argument is
  /// **not required**, but to use with `ReflectiveInjector` it is required
  /// unless you have no arguments:
  /// ```dart
  /// ReflectiveInjector.resolveAndCreate([
  ///   new Provider(Foo, useFactory: (Bar bar) => new Foo(bar), deps: [Bar]),
  /// ]);
  /// ```
  final Function useFactory;

  /// Optional; dependencies to inject and provide when invoking [useFactory].
  final List<Object> deps;

  /// Whether to treat this provider as a "multi" provider (multiple values).
  ///
  /// A multi-provider collects all tokens, and returns a [List<T>] instead of
  /// just a value [T] for given injection of [token]:
  /// ```dart
  /// const usPresidents = const OpaqueToken('usPresidents');
  ///
  /// const presidentialProviders = const [
  ///   const MultiProvider.ofTokenToValue(usPresidents, 'George Washington'),
  ///   const MultiProvider.ofTokenToValue(usPresidents, 'Abraham Lincoln'),
  /// ];
  ///
  /// // Later on, inside an Injector.
  /// void printPresidents(Injector injector) {
  ///   List<String> presidents = injector.get(usPresidents);
  ///   print(presidents.join(', '));
  /// }
  /// ```
  final bool multi;

  /// Configures a [Provider] based on the arguments provided.
  ///
  /// **NOTE**: This constructor is _soft deprecated_. It is considered best
  /// practice to use named variants of this class, such as the following:
  ///
  /// * `useClass` -> [ClassProvider]
  /// * `useValue` -> [ValueProvider]
  /// * `useFactory` -> [FactoryProvider]
  /// * `useExisting` -> [ExistingProvider]
  const Provider(
    this.token, {
    this.useClass,
    this.useValue: noValueProvided,
    this.useExisting,
    this.useFactory,
    this.deps,
    this.multi: false,
  });

  // Internal. See `listOfMulti`.
  List<T> _listOfMulti() => <T>[];
}

/// **INTERNAL ONLY**: Used to provide type inference for `multi: true`.
@visibleForTesting
List<T> listOfMulti<T>(Provider<T> provider) => provider._listOfMulti();

/// Describes at compile-time configuring to return an instance of a `class`.
///
/// If [T] is provided (i.e. not [dynamic]), it must be the same as [token].
///
/// A class that provides itself:
/// ```dart
/// const ClassProvider(Service);
/// ```
///
/// A class that provides itself with a different implementation:
/// ```dart
/// const ClassProvider(Service, useClass: CachedService);
/// ```
class ClassProvider<T> extends Provider<T> {
  const ClassProvider(
    Type token, {
    Type useClass,
    bool multi: false,
  })
      : super(
          token,
          useClass: useClass ?? token,
          multi: multi,
        );
}
