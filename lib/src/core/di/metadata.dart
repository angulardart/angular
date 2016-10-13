/// A parameter metadata that specifies a dependency.
///
/// ## Example
///
/// ```dart
/// class Engine {}
///
/// @Injectable()
/// class Car {
///   final Engine engine;
///   Car(@Inject("MyEngine") this.engine);
/// }
///
/// var engine = new Engine();
///
/// var injector = Injector.resolveAndCreate([
///  new Provider("MyEngine", useValue: engine),
///  Car
/// ]);
///
/// expect(injector.get(Car).engine, same(engine));
/// ```
///
/// When `@Inject()` is not present, [Injector] will use the type annotation of
/// the parameter.
///
/// ## Example
///
/// ```dart
/// class Engine {}
///
/// @Injectable()
/// class Car {
///   Car(Engine engine) {} //same as Car(@Inject(Engine) Engine engine)
/// }
///
/// var injector = Injector.resolveAndCreate([Engine, Car]);
/// expect(injector.get(Car).engine, new isInstanceOf<Engine>());
/// ```
@Deprecated('Use Inject instead')
class InjectMetadata {
  final token;
  const InjectMetadata(this.token);
  String toString() => '@Inject(${tokenToString(token)})';

  static String tokenToString(token) {
    RegExp funcMatcher = new RegExp(r"from Function '(\w+)'");
    String tokenStr = token.toString();
    var match = funcMatcher.firstMatch(tokenStr);
    return (match != null) ? match.group(1) : tokenStr;
  }
}

/// A parameter metadata that marks a dependency as optional.
///
/// [Injector] provides `null` if the dependency is not found.
///
/// ## Example
///
/// ```dart
/// class Engine {}
///
/// @Injectable()
/// class Car {
///   final Engine engine;
///   constructor(@Optional() this.engine);
/// }
///
/// var injector = Injector.resolveAndCreate([Car]);
/// expect(injector.get(Car).engine, isNull);
/// ```
@Deprecated('Use Optional instead')
class OptionalMetadata {
  const OptionalMetadata();

  String toString() {
    return '@Optional()';
  }
}

/// `DependencyMetadata` is used by the framework to extend DI.
///
/// This is internal to Angular and should not be used directly.
@Deprecated('Use Dependency instead')
class DependencyMetadata {
  const DependencyMetadata();

  dynamic get token => null;
}

/// A marker metadata that marks a class as available to [Injector] for
/// creation.
///
/// This is internal to Angular and should not be used directly.
@Deprecated('Use Injectable instead')
class InjectableMetadata {
  const InjectableMetadata();
}

/// Specifies that an [Injector] should retrieve a dependency only from itself.
///
/// ## Example
///
/// ```dart
/// class Dependency {}
///
/// @Injectable()
/// class NeedsDependency {
///   final Dependency dependency;
///   NeedsDependency(@Self() this.dependency);
/// }
///
/// var inj = Injector.resolveAndCreate([Dependency, NeedsDependency]);
/// var nd = inj.get(NeedsDependency);
///
/// expect(nd.dependency, new isInstanceOf<Dependency>());
///
/// inj = Injector.resolveAndCreate([Dependency]);
/// var child = inj.resolveAndCreateChild([NeedsDependency]);
/// expect(() => child.get(NeedsDependency), throws);
/// ```
@Deprecated('Use Self instead')
class SelfMetadata {
  const SelfMetadata();

  String toString() {
    return '@Self()';
  }
}

/// Specifies that the dependency resolution should start from the parent
/// injector.
///
/// ## Example
///
/// ```dart
/// class Dependency {}
///
/// @Injectable()
/// class NeedsDependency {
///   final Dependency dependency;
///   NeedsDependency(@Self() this.dependency);
/// }
///
/// var parent = Injector.resolveAndCreate([Dependency]);
/// var child = parent.resolveAndCreateChild([NeedsDependency]);
/// expect(child.get(NeedsDependency).dependency, new
///     isInstanceOf<Dependency>());
///
/// var inj = Injector.resolveAndCreate([Dependency, NeedsDependency]);
/// expect(() => inj.get(NeedsDependency), throws);
/// ```
@Deprecated('Use SkipSelf instead')
class SkipSelfMetadata {
  const SkipSelfMetadata();

  String toString() {
    return '@SkipSelf()';
  }
}

/// Specifies that an injector should retrieve a dependency from any injector
/// until reaching the closest host.
///
/// In Angular, a component element is automatically declared as a host for all
/// the injectors in its view.
///
/// ## Example
///
/// In the following example `App` contains `ParentCmp`, which contains
/// `ChildDirective`.  So `ParentCmp` is the host of `ChildDirective`.
///
/// `ChildDirective` depends on two services: `HostService` and `OtherService`.
/// `HostService` is defined at `ParentCmp`, and `OtherService` is defined at
/// `App`.
///
///```dart
/// class OtherService {}
/// class HostService {}
///
/// @Directive(
///   selector: 'child-directive'
/// )
/// class ChildDirective {
///   ChildDirective(
///       @Optional() @Host() OtherService os,
///       @Optional() @Host() HostService hs) {
///     print("os is null", os);
///     print("hs is NOT null", hs);
///   }
/// }
///
/// @Component(
///   selector: 'parent-cmp',
///   providers: const [HostService],
///   template: '''
///     Dir: <child-directive></child-directive>
///   ''',
///   directives: const [ChildDirective]
/// )
/// class ParentCmp {}
///
/// @Component(
///   selector: 'app',
///   providers: const [OtherService],
///   template: '''
///     Parent: <parent-cmp></parent-cmp>
///   ''',
///   directives: const [ParentCmp]
/// )
/// class App {}
///
/// bootstrap(App);
///```
@Deprecated('Use Host instead')
class HostMetadata {
  const HostMetadata();

  String toString() => '@Host()';
}
