library angular2.src.core.di.provider;

import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show normalizeBool, Type, isType, isBlank, isFunction, stringify;

/// A special string used as the default value of `useValue` parameter.
///
/// Indicates that no value was provided. This is to distinguish `null` value
/// from default factory.
const noValueProvided = '__noValueProvided__';

/// Describes how the [Injector] should instantiate a given token.
///
/// See [provide].
///
/// ### Example ([live demo](http://plnkr.co/edit/GNAyj6K6PfYg2NBzgwZ5?p%3Dpreview&p=preview))
///
///     var injector = Injector.resolveAndCreate([
///       new Provider("message", { useValue: 'Hello' })
///     ]);
///     expect(injector.get("message")).toEqual('Hello');
class Provider {
  /// Token used when retrieving this provider. Usually, it is a type [Type].
  final token;

  /// Binds a DI token to an implementation class.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/RSTG86qgmoxCyj9SWPwY?p=preview))
  ///
  /// Because [useExisting] and [useClass] are often confused, the example contains
  /// both use cases for easy comparison.
  ///
  /// ```typescript
  /// class Vehicle {}
  ///
  /// class Car extends Vehicle {}
  ///
  /// var injectorClass = Injector.resolveAndCreate([
  ///   Car,
  ///   new Provider(Vehicle, { useClass: Car })
  /// ]);
  /// var injectorAlias = Injector.resolveAndCreate([
  ///   Car,
  ///   new Provider(Vehicle, { useExisting: Car })
  /// ]);
  ///
  /// expect(injectorClass.get(Vehicle)).not.toBe(injectorClass.get(Car));
  /// expect(injectorClass.get(Vehicle) instanceof Car).toBe(true);
  ///
  /// expect(injectorAlias.get(Vehicle)).toBe(injectorAlias.get(Car));
  /// expect(injectorAlias.get(Vehicle) instanceof Car).toBe(true);
  /// ```
  final Type useClass;

  /// Binds a DI token to a value.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/UFVsMVQIDe7l4waWziES?p=preview))
  ///
  /// ```javascript
  /// var injector = Injector.resolveAndCreate([
  ///   new Provider("message", { useValue: 'Hello' })
  /// ]);
  ///
  /// expect(injector.get("message")).toEqual('Hello');
  /// ```
  final useValue;

  /// Binds a DI token to an existing token.
  ///
  /// [Injector] returns the same instance as if the provided token was used.
  /// This is in contrast to `useClass` where a separate instance of `useClass` is returned.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/QsatsOJJ6P8T2fMe9gr8?p=preview))
  ///
  /// Because `useExisting` and `useClass` are often confused the example contains
  /// both use cases for easy comparison.
  ///
  /// ```typescript
  /// class Vehicle {}
  ///
  /// class Car extends Vehicle {}
  ///
  /// var injectorAlias = Injector.resolveAndCreate([
  ///   Car,
  ///   new Provider(Vehicle, { useExisting: Car })
  /// ]);
  /// var injectorClass = Injector.resolveAndCreate([
  ///   Car,
  ///   new Provider(Vehicle, { useClass: Car })
  /// ]);
  ///
  /// expect(injectorAlias.get(Vehicle)).toBe(injectorAlias.get(Car));
  /// expect(injectorAlias.get(Vehicle) instanceof Car).toBe(true);
  ///
  /// expect(injectorClass.get(Vehicle)).not.toBe(injectorClass.get(Car));
  /// expect(injectorClass.get(Vehicle) instanceof Car).toBe(true);
  /// ```
  final useExisting;

  /// Binds a DI token to a function which computes the value.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/Scoxy0pJNqKGAPZY1VVC?p=preview))
  ///
  /// ```typescript
  /// var injector = Injector.resolveAndCreate([
  ///   new Provider(Number, { useFactory: () => { return 1+2; }}),
  ///   new Provider(String, { useFactory: (value) => { return "Value: " + value; },
  ///                       deps: [Number] })
  /// ]);
  ///
  /// expect(injector.get(Number)).toEqual(3);
  /// expect(injector.get(String)).toEqual('Value: 3');
  /// ```
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
  /// ### Example ([live demo](http://plnkr.co/edit/Scoxy0pJNqKGAPZY1VVC?p=preview))
  ///
  /// ```typescript
  /// var injector = Injector.resolveAndCreate([
  ///   new Provider(Number, { useFactory: () => { return 1+2; }}),
  ///   new Provider(String, { useFactory: (value) => { return "Value: " + value; },
  ///                       deps: [Number] })
  /// ]);
  ///
  /// expect(injector.get(Number)).toEqual(3);
  /// expect(injector.get(String)).toEqual('Value: 3');
  /// ```
  ///
  /// Used in conjunction with `useFactory`.
  final List<Object> dependencies;

  final bool _multi;

  const Provider(token,
      {Type useClass,
      dynamic useValue: noValueProvided,
      dynamic useExisting,
      Function useFactory,
      String useProperty,
      List<Object> deps,
      bool multi})
      : token = token,
        useClass = useClass,
        useValue = useValue,
        useExisting = useExisting,
        useFactory = useFactory,
        useProperty = useProperty,
        dependencies = deps,
        _multi = multi;

  /// Creates multiple providers matching the same token (a multi-provider).
  ///
  /// Multi-providers are used for creating pluggable service, where the system comes
  /// with some default providers, and the user can register additional providers.
  /// The combination of the default providers and the additional providers will be
  /// used to drive the behavior of the system.
  ///
  /// ### Example
  ///
  /// ```typescript
  /// var injector = Injector.resolveAndCreate([
  ///   new Provider("Strings", { useValue: "String1", multi: true}),
  ///   new Provider("Strings", { useValue: "String2", multi: true})
  /// ]);
  ///
  /// expect(injector.get("Strings")).toEqual(["String1", "String2"]);
  /// ```
  ///
  /// Multi-providers and regular providers cannot be mixed. The following
  /// will throw an exception:
  ///
  /// ```typescript
  /// var injector = Injector.resolveAndCreate([
  ///   new Provider("Strings", { useValue: "String1", multi: true }),
  ///   new Provider("Strings", { useValue: "String2"})
  /// ]);
  /// ```
  bool get multi {
    return normalizeBool(this._multi);
  }
}

/// See [Provider] instead.
@Deprecated('Use Provider instead')
class Binding extends Provider {
  const Binding(token,
      {Type toClass,
      dynamic toValue: noValueProvided,
      dynamic toAlias,
      Function toFactory,
      List<Object> deps,
      bool multi})
      : super(token,
            useClass: toClass,
            useValue: toValue,
            useExisting: toAlias,
            useFactory: toFactory,
            deps: deps,
            multi: multi);

  Type get toClass {
    return this.useClass;
  }

  get toAlias {
    return this.useExisting;
  }

  get toFactory {
    return this.useFactory;
  }

  get toValue {
    return this.useValue;
  }
}

/// Deprecated Use provide instead.
@Deprecated('Use provide instead')
ProviderBuilder bind(token) {
  return new ProviderBuilder(token);
}

/// Helper class for the [bind] function.
class ProviderBuilder {
  var token;
  ProviderBuilder(this.token) {}

  /// Binds a DI token to a class.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/ZpBCSYqv6e2ud5KXLdxQ?p=preview))
  ///
  /// Because `toAlias` and `toClass` are often confused, the example contains
  /// both use cases for easy comparison.
  ///
  /// ```typescript
  /// class Vehicle {}
  ///
  /// class Car extends Vehicle {}
  ///
  /// var injectorClass = Injector.resolveAndCreate([
  ///   Car,
  ///   provide(Vehicle, {useClass: Car})
  /// ]);
  /// var injectorAlias = Injector.resolveAndCreate([
  ///   Car,
  ///   provide(Vehicle, {useExisting: Car})
  /// ]);
  ///
  /// expect(injectorClass.get(Vehicle)).not.toBe(injectorClass.get(Car));
  /// expect(injectorClass.get(Vehicle) instanceof Car).toBe(true);
  ///
  /// expect(injectorAlias.get(Vehicle)).toBe(injectorAlias.get(Car));
  /// expect(injectorAlias.get(Vehicle) instanceof Car).toBe(true);
  /// ```
  Provider toClass(Type type) {
    if (!isType(type)) {
      throw new BaseException(
          '''Trying to create a class provider but "${stringify(type)}" is not a class!''');
    }
    return new Provider(this.token, useClass: type);
  }

  /// Binds a DI token to a value.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/G024PFHmDL0cJFgfZK8O?p=preview))
  ///
  /// ```typescript
  /// var injector = Injector.resolveAndCreate([
  ///   provide('message', {useValue: 'Hello'})
  /// ]);
  ///
  /// expect(injector.get('message')).toEqual('Hello');
  /// ```
  Provider toValue(dynamic value) {
    return new Provider(this.token, useValue: value);
  }

  /// Binds a DI token to an existing token.
  ///
  /// Angular will return the same instance as if the provided token was used. (This is
  /// in contrast to `useClass` where a separate instance of `useClass` will be returned.)
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/uBaoF2pN5cfc5AfZapNw?p=preview))
  ///
  /// Because `toAlias` and `toClass` are often confused, the example contains
  /// both use cases for easy comparison.
  ///
  /// ```typescript
  /// class Vehicle {}
  ///
  /// class Car extends Vehicle {}
  ///
  /// var injectorAlias = Injector.resolveAndCreate([
  ///   Car,
  ///   provide(Vehicle, {useExisting: Car})
  /// ]);
  /// var injectorClass = Injector.resolveAndCreate([
  ///   Car,
  ///   provide(Vehicle, {useClass: Car})
  /// ]);
  ///
  /// expect(injectorAlias.get(Vehicle)).toBe(injectorAlias.get(Car));
  /// expect(injectorAlias.get(Vehicle) instanceof Car).toBe(true);
  ///
  /// expect(injectorClass.get(Vehicle)).not.toBe(injectorClass.get(Car));
  /// expect(injectorClass.get(Vehicle) instanceof Car).toBe(true);
  /// ```
  Provider toAlias(dynamic aliasToken) {
    if (isBlank(aliasToken)) {
      throw new BaseException(
          '''Can not alias ${ stringify ( this . token )} to a blank value!''');
    }
    return new Provider(this.token, useExisting: aliasToken);
  }

  /// Binds a DI token to a function which computes the value.
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/OejNIfTT3zb1iBxaIYOb?p=preview))
  ///
  /// ```typescript
  /// var injector = Injector.resolveAndCreate([
  ///   provide(Number, {useFactory: () => { return 1+2; }}),
  ///   provide(String, {useFactory: (v) => { return "Value: " + v; }, deps: [Number]})
  /// ]);
  ///
  /// expect(injector.get(Number)).toEqual(3);
  /// expect(injector.get(String)).toEqual('Value: 3');
  /// ```
  Provider toFactory(Function factory, [List<dynamic> dependencies]) {
    if (!isFunction(factory)) {
      throw new BaseException(
          '''Trying to create a factory provider but "${ stringify ( factory )}" is not a function!''');
    }
    return new Provider(this.token, useFactory: factory, deps: dependencies);
  }
}

/// Creates a [Provider].
///
/// To construct a [Provider], bind a `token` to either a class, a value, a factory function,
/// or to an existing `token`.
/// See [ProviderBuilder] for more details.
///
/// The `token` is most commonly a class or [OpaqueToken-class.html].
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
