/// A special string used as the default value of `useValue` parameter.
///
/// Indicates that no value was provided. This is to distinguish `null` value
/// from default factory.
const noValueProvided = '__noValueProvided__';

/// Describes how an [Injector] should instantiate a given token.
///
/// See [provide] and the [Dependency Injection][di] page of the Angular
/// Guide.
///
///     var injector = Injector.resolveAndCreate([
///       new Provider("message", useValue: 'Hello')
///     ]);
///
///     expect(injector.get('message'), 'Hello');
///
/// [di]: docs/guide/dependency-injection.html#injector-providers
class Provider {
  /// Token used when retrieving this provider. Usually, it is a type [Type].
  final token;

  /// Binds a DI token to an implementation class.
  ///
  /// Because [useExisting] and [useClass] are often confused, the example
  /// contains both use cases for easy comparison.
  ///
  ///     class Vehicle {}
  ///
  ///     class Car extends Vehicle {}
  ///
  ///     var injectorClass = Injector.resolveAndCreate([
  ///       Car,
  ///       new Provider(Vehicle, useClass: Car)
  ///     ]);
  ///     var injectorAlias = Injector.resolveAndCreate([
  ///       Car,
  ///       new Provider(Vehicle, useExisting: Car)
  ///     ]);
  ///
  ///     expect(injectorClass.get(Vehicle) == injectorClass.get(Car), isFalse);
  ///     expect(injectorClass.get(Vehicle) is Car, isTrue);
  ///
  ///     expect(injectorAlias.get(Vehicle) == injectorAlias.get(Car), isTrue);
  ///     expect(injectorAlias.get(Vehicle) is Car, isTrue);
  ///
  final Type useClass;

  /// Binds a DI token to a value.
  ///
  ///     var injector = Injector.resolveAndCreate([
  ///       new Provider('message', useValue: 'Hello')
  ///     ]);
  ///
  ///     expect(injector.get('message'), 'Hello');
  ///
  final useValue;

  /// Binds a DI token to an existing token.
  ///
  /// [Injector] returns the same instance as if the provided token was used.
  /// This is in contrast to [useClass] where a separate instance of [useClass]
  /// is returned.
  ///
  /// Because [useExisting] and [useClass] are often confused the example
  /// contains both use cases for easy comparison.
  ///
  ///     class Vehicle {}
  ///
  ///     class Car extends Vehicle {}
  ///
  ///     var injectorAlias = Injector.resolveAndCreate([
  ///       Car,
  ///       new Provider(Vehicle, useExisting: Car)
  ///     ]);
  ///     var injectorClass = Injector.resolveAndCreate([
  ///       Car,
  ///       new Provider(Vehicle, useClass: Car)
  ///     ]);
  ///
  ///     expect(injectorAlias.get(Vehicle) == injectorAlias.get(Car), isTrue);
  ///     expect(injectorAlias.get(Vehicle) is Car, isTrue);
  ///
  ///     expect(injectorClass.get(Vehicle) != injectorClass.get(Car), isTrue);
  ///     expect(injectorClass.get(Vehicle) is Car, isTrue);
  ///
  final useExisting;

  /// Binds a DI token to a function which computes the value.
  ///
  ///     var injector = Injector.resolveAndCreate([
  ///       new Provider(Number, useFactory: () => return 1+2;),
  ///       new Provider(String, useFactory: (value) => "Value: " + value;,
  ///            deps: const [Number])
  ///     ]);
  ///
  ///     expect(injector.get(Number) , 3);
  ///     expect(injector.get(String), 'Value: 3');
  ///
  /// Used in conjunction with dependencies.
  final Function useFactory;

  /// Specifies the property of the configuration class to use as value.
  ///
  /// Only used in conjunction with the @Injector class.
  final String useProperty;

  /// Specifies a set of dependencies
  /// (as `token`s) which should be injected into the factory function.
  ///
  ///     var injector = Injector.resolveAndCreate([
  ///       new Provider(Number, useFactory: () => 1+2;),
  ///       new Provider(String, useFactory: (value) => "Value: $value"; ,
  ///                           deps: [Number])
  ///     ]);
  ///
  ///     expect(injector.get(Number), 3);
  ///     expect(injector.get(String), 'Value: 3');
  ///
  /// Used in conjunction with [useFactory].
  final List<Object> dependencies;
  final bool _multi;

  const Provider(this.token,
      {this.useClass,
      this.useValue: noValueProvided,
      this.useExisting,
      this.useFactory,
      this.useProperty,
      List<Object> deps,
      bool multi})
      : dependencies = deps,
        _multi = multi;

  /// Creates multiple providers matching the same token (a multi-provider).
  ///
  /// Multi-providers are used for creating pluggable service, where the system
  /// comes with some default providers, and the user can register additional
  /// providers. The combination of the default providers and the additional
  /// providers will be used to drive the behavior of the system.
  ///
  ///     var injector = Injector.resolveAndCreate([
  ///       new Provider("Strings", useValue: "String1", multi: true),
  ///       new Provider("Strings", useValue: "String2", multi: true)
  ///     ]);
  ///
  ///     expect(injector.get("Strings"), ["String1", "String2"]);
  ///
  /// Multi-providers and regular providers cannot be mixed. The following
  /// will throw an exception:
  ///
  ///
  ///     var injector = Injector.resolveAndCreate([
  ///       new Provider("Strings", { useValue: "String1", multi: true }),
  ///       new Provider("Strings", { useValue: "String2"})
  ///     ]);
  ///
  bool get multi => _multi ?? false;
}

/// Creates an injector [Provider] for the given [token] based on a given
///
/// - Class
/// - Value
/// - Factory function, or
/// - Another token
///
/// The [token] is most commonly a class or an opaque token. More details
/// concerning providers can be found in the [Dependency Injection][di] page
/// of the Angular Guide.
///
/// ### Example
///
/// {@example docs/toh-6/web/main.dart}
///
/// [di]: docs/guide/dependency-injection.html#injector-providers
Provider provide(token,
    {Type useClass,
    dynamic useValue: noValueProvided,
    dynamic useExisting,
    Function useFactory,
    List<Object> deps,
    bool multi}) {
  return new Provider(token,
      useClass: useClass,
      useValue: useValue,
      useExisting: useExisting,
      useFactory: useFactory,
      deps: deps,
      multi: multi);
}
