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
class Inject {
  final token;

  const Inject(this.token);

  @override
  String toString() => '@Inject($token)';
}

/// Compile-time metadata that marks a class [Type] or [Function] for injection.
///
/// The `@Injectable()` annotation has two valid uses:
///
/// 1. On a class [Type]
/// 2. On a top-level [Function]
///
/// ## Use #1: A class [Type]
/// The class must be one of the following:
///
///  - non-abstract with a public or default constructor
///  - abstract but with a factory constructor
///
/// A class annotated with `@Injectable()` can have only a single constructor
/// or the default constructor. The DI framework resolves the dependencies
/// and invokes the constructor with the resolved values.
///
/// ### Example
///
/// ```dart
/// // Use the default constructor to create a new instance of MyService.
/// @Injectable()
/// class MyService {}
///
/// // Use the defined constructor to create a new instance of MyService.
/// //
/// // Each positional argument is treated as a dependency to be resolved.
/// @Injectable()
/// class MyService {
///   MyService(Dependency1 d1, Dependency2 d2)
/// }
///
/// // Use the factory constructor to create a new instance of MyServiceImpl.
/// @Injectable()
/// abstract class MyService {
///   factory MyService() => new MyServiceImpl();
/// }
/// ```
///
/// ## Use #2: A top-level [Function]
///
/// The `Injectable()` annotation works with top-level functions
/// when used with `useFactory`.
///
/// ### Example
///
/// ```dart
/// // Could be put anywhere DI providers are allowed.
/// const Provide(MyService, useFactory: createMyService);
///
/// // A `Provide` may now use `createMyService` via `useFactory`.
/// @Injectable()
/// MyService createMyService(Dependency1 d1, Dependency2 d2) => ...
/// ```
class Injectable {
  const Injectable();
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
class Optional {
  const Optional();
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
class Self {
  const Self();
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
///   NeedsDependency(@SkipSelf() this.dependency);
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
class SkipSelf {
  const SkipSelf();
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
class Host {
  const Host();
}
