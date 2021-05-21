import 'package:meta/meta.dart';
import 'package:angular/src/utilities.dart';

import 'di_tokens.dart';

/// A marker that represents a lack-of-value for the `useValue` parameter.
const Object noValueProvided = '__noValueProvided__';

/// A contract for creating implementations of [Injector] at runtime.
///
/// Implementing this interface removes the need to do inspection of the
/// presence of fields on various [Provider] implementations, as well allows
/// further optimizations in the future.
abstract class RuntimeInjectorBuilder {
  /// Configures the injector for a [ClassProvider].
  Object useClass(Type clazz, {List<Object>? deps});

  /// Configures the injector for an [ExistingProvider].
  Object useExisting(Object to);

  /// Configures the injector for a [FactoryProvider].
  Object useFactory(Function factory, {List<Object>? deps});

  /// Configures the injector for a [ValueProvider].
  Object useValue(Object value);
}

/// Short-hand for `Provider(...)`.
///
/// It is strongly recommended to prefer the constructor, not this function,
/// and to use `const Provider(...)` whenever possible to enable future
/// optimizations.
Provider<T> provide<T extends Object>(
  Object token, {
  Type? useClass,
  // TODO(b/156495978): Change to Object? and remove noValueProvided.
  Object useValue = noValueProvided,
  Object? useExisting,
  Function? useFactory,
  List<Object>? deps,
}) =>
    Provider<T>(
      token,
      useClass: useClass,
      useValue: useValue,
      useExisting: useExisting,
      useFactory: useFactory,
      deps: deps,
    );

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
class Provider<T extends Object> {
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
  final Type? useClass;

  /// Constant value to use when [token] is injected.
  ///
  /// It is recommended to use [useValue] with an [OpaqueToken] as [token]:
  /// ```dart
  /// const animationDelay = OpaqueToken<Duration>('animationDelay');
  ///
  /// const Provider(animationDelay, useValue: Duration(seconds: 1));
  /// ```
  ///
  /// **NOTE**: The AngularDart compiler has limited heuristics for supporting
  /// complex nested objects beyond simple literals. If you encounter problems
  /// it is recommended to use [useFactory] instead.
  ///
  /// TODO(b/156495978): Change to Object?.
  final Object useValue;

  /// An existing token to redirect to when [token] is injected.
  ///
  /// Commonly used for deprecation strategies or to-export an interface.
  final Object? useExisting;

  /// A factory function to invoke when [token] is injected.
  ///
  /// For static forms of injection (i.e. compile-time), the [deps] argument is
  /// **not required**, but to use with `ReflectiveInjector` it is required
  /// unless you have no arguments:
  /// ```dart
  /// ReflectiveInjector.resolveAndCreate([
  ///   Provider(Foo, useFactory: (Bar bar) => new Foo(bar), deps: [Bar]),
  /// ]);
  /// ```
  final Function? useFactory;

  /// Optional; dependencies to inject and provide when invoking [useFactory].
  final List<Object>? deps;

  /// Configures a [Provider] based on the arguments provided.
  ///
  /// **NOTE**: This constructor is _soft deprecated_. It is considered best
  /// practice to use named variants of this class, such as the following:
  ///
  /// * `useClass` -> [ClassProvider]
  /// * `useValue` -> [ValueProvider]
  /// * `useFactory` -> [FactoryProvider]
  /// * `useExisting` -> [ExistingProvider]
  const factory Provider(
    Object token, {
    Type? useClass,
    Object useValue,
    Object? useExisting,
    Function? useFactory,
    List<Object>? deps,
  }) = Provider<T>._;

  // Prevents extending this class.
  const Provider._(
    this.token, {
    this.useClass,
    this.useValue = noValueProvided,
    this.useExisting,
    this.useFactory,
    this.deps,
  });

  /// Configures the provided [builder] using this provider object.
  ///
  /// See [buildAtRuntime] for the implementation invoked in the framework.
  @protected
  Object _buildAtRuntime(RuntimeInjectorBuilder builder) {
    if (!identical(useValue, noValueProvided)) {
      return builder.useValue(useValue);
    }
    final useFactory = this.useFactory;
    if (useFactory != null) {
      return builder.useFactory(useFactory, deps: deps);
    }
    final useExisting = this.useExisting;
    if (useExisting != null) {
      return builder.useExisting(useExisting);
    }
    return builder.useClass(useClass ?? unsafeCast<Type>(token), deps: deps);
  }
}

/// **INTERNAL ONLY**: Used to build an injector at runtime.
Object buildAtRuntime(Provider provider, RuntimeInjectorBuilder builder) {
  return provider._buildAtRuntime(builder);
}

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
@optionalTypeArgs
class ClassProvider<T extends Object> extends Provider<T> {
  const factory ClassProvider(
    Type type, {
    Type useClass,
  }) = ClassProvider<T>._;

  const factory ClassProvider.forToken(
    OpaqueToken<T> token, {
    Type useClass,
  }) = ClassProvider<T>._;

  // Prevents extending this class.
  const ClassProvider._(
    Object token, {
    Type? useClass,
  }) : super._(
          token,
          useClass: useClass ?? token as Type,
        );
}

/// Describes at compile-time configuring to redirect to another token.
///
/// The provided [token] instead injects [useExisting].
///
/// Commonly used for deprecation strategies or to-export an interface.
@optionalTypeArgs
class ExistingProvider<T extends Object> extends Provider<T> {
  const factory ExistingProvider(
    Type type,
    Object useExisting,
  ) = ExistingProvider<T>._;

  const factory ExistingProvider.forToken(
    OpaqueToken<T> token,
    Object useExisting,
  ) = ExistingProvider<T>._;

  // Prevents extending this class.
  const ExistingProvider._(
    Object token,
    Object useExisting,
  ) : super._(
          token,
          useExisting: useExisting,
        );
}

/// Describes at compile-time configuring to invoke a factory function.
///
/// For static forms of injection (i.e. compile-time), the [deps] argument is
/// **not required**, but to use with `ReflectiveInjector` it is required
/// unless you have no arguments:
/// ```dart
/// ReflectiveInjector.resolveAndCreate([
///   FactoryProvider(Foo, (Bar bar) => new Foo(bar), deps: [Bar]),
/// ]);
/// ```
@optionalTypeArgs
class FactoryProvider<T extends Object> extends Provider<T> {
  const factory FactoryProvider(
    Type type,
    Function useFactory, {
    List<Object>? deps,
  }) = FactoryProvider<T>._;

  const factory FactoryProvider.forToken(
    OpaqueToken<T> token,
    Function useFactory, {
    List<Object>? deps,
  }) = FactoryProvider<T>._;

  // Prevents extending this class.
  const FactoryProvider._(
    Object token,
    Function useFactory, {
    List<Object>? deps,
  }) : super._(
          token,
          useFactory: useFactory,
          deps: deps,
        );
}

/// Describes at compile-time using a constant value to represent a token.
///
/// It is recommended to use [useValue] with an [OpaqueToken] as [token]:
/// ```dart
/// const animationDelay = OpaqueToken<Duration>('animationDelay');
///
/// const ValueProvider.forToken(animationDelay, Duration(seconds: 1));
/// ```
///
/// **NOTE**: The AngularDart compiler has limited heuristics for supporting
/// complex nested objects beyond simple literals, including collection literals
/// like a [List] or [Map] where you might expect specific reified types. If you
/// encounter problems it is recommended to use [FactoryProvider] instead.
@optionalTypeArgs
class ValueProvider<T extends Object> extends Provider<T> {
  const factory ValueProvider(
    Type type,
    T useValue,
  ) = ValueProvider<T>._;

  const factory ValueProvider.forToken(
    OpaqueToken<T> token,
    T useValue,
  ) = ValueProvider<T>._;

  // Prevents extending this class.
  const ValueProvider._(
    Object token,
    T useValue,
  ) : super._(
          token,
          useValue: useValue,
        );
}
