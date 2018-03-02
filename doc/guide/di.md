# Dependency Injection

There are many different ways to use AngularDart to provide and utilize dependency injection throughout your application, components, and services. This guide is meant to serve as a **development tool** and to help push **best practices** from the developers of the AngularDart framework.

* [Providers](#providers)
    * [DO use the "named" providers](#do-use-the-named-providers)
    * [DO use factories for configuration](#do-use-factories-for-configuration)
    * [DO use `const` providers](#do-use-const-providers)
* [Injectors](#injectors)
    * [AVOID using `ReflectiveInjector`](#avoid-using-reflectiveinjector)

## Providers

### DO use the "named" providers

While not formally deprecated, `provide(...)` and `Provider(...)` require certain combinations of named optional parameters, and allow combinations that otherwise will not compile or perform as intended. For example:

**BAD**:

```dart
// This is valid with the older syntax. What does it mean?
const Provider(
  Foo,
  useClass: CachedFoo,
  useExisting: OtherFoo,
  useFactory: createCachedFoo,
  useValue: null,
);
```

Instead, use the "named" providers (`ClassProvider`, `ExistingProvider`, `FactoryProvider`, and `ValueProvider`) in order to make your providers more readable, in some cases more terse, and use the definition of the class to help guide the configuration.

**GOOD**:

```dart
const ClassProvider(Foo, CachedFoo);
const ExistingProvider(Foo, OtherFoo);
const FactoryProvider(Foo, createCachedFoo);
const ValueProvider(Foo, null);
```

### DO use factories for configuration

As part of [avoiding runtime configured providers](#do-use-const-providers), you may have or desire patterns where dependency injection varies based on some runtime information, or information that is otherwise not expressable as a constant. Use `FactoryProvider` instead.

**BAD**:

```dart
Provider bindUser(Flags flags) {
  if (flags.isAdminUser) {
    return new ClassProvider(User, useClass: AdminUser);
  }
  return new ClassProvider(Use, useClass: RegularUser);
}
```

**GOOD**:

```dart
const FactoryProvider(User, useFactory: createUserFromFlags);

User createUserFromFlags(Flags flags) {
  return flags.isAdminUser ? new AdminUser() : new RegularUser();
}
```

### DO Use `const` providers

It can be tempting to create and configure providers at runtime, either using `new Provider(...)` or `provide(...)`. While not formally deprecated, runtime configuration of providers relies on side-effects in your program, and [should be avoided](#avoid-using-reflectiveinjector).

**BAD**:

```dart
void main() {
  var injector = ReflectiveInjector.resolveAndCreate([
    new ClassProvider(HeroService),
  ]);
}
```

Even if you still rely on this API partially, new providers are highly recommended to use `const` in order to be able to better injectors in the future:

**GOOD**:

```dart
void main() {
  var injector = ReflectiveInjector.resolveAndCreate([
    const ClassProvider(HeroService),
  ]);
}
```

## Injectors

### AVOID using `ReflectiveInjector`

While not formally deprecated, `ReflectiveInjector` relies on importing `.dart` files having side-effects on your program, and negatively effecting tree-shaking by making all classes and functions annotated with `@Injectable` retained, regardless of use.

**BAD**:

```dart
void main() {
  var injector = ReflectiveInjector.resolveAndCreate([
    const ClassProvider(HeroService),
  ]);
}
```

AngularDart gives a few alternative options when creating injectors.

**GOOD**: Use `Injector.map` to create a simple dynamic injector.

```dart
void main() {
  var injector = new Injector.map({
    HeroService: new HeroService(),
  });
  // ...
}
```

**GOOD**: Use `providers: const [ ... ]` in `@Component` or `@Directive`.

```dart
@Component(
  selector: 'comp',
  providers: const [
    const ClassProvider(HeroService),
  ],
)
class Comp {}
```

**GOOD**: Use `@GenerateInjector` to generate an injector at compile-time.

```dart
// assume you are currently in file.dart
import 'file.template.dart' as ng;

@GenerateInjector(const [
  const ClassProvider(HeroService),
])
final InjectorFactory heroInjector = ng.heroInjector$Injector;
```

## Components