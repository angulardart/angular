# Effective Angular: Dependency Injection

> **NOTE**: This is a work-in-progress, and not yet final. Some of the links may
> be substituted with `(...)`, and some TODOs or missing parts may be in the
> documentation.

There are many different ways to use AngularDart to provide and utilize
dependency injection throughout your application, components, and services. This
guide is meant to serve as a **development tool** and to help push **best
practices** from the developers of the AngularDart framework.

*   [Providers](#providers)
    *   [DO use the "named" providers](#do-use-the-named-providers)
    *   [DO use factories for
        configuration](#do-use-factories-for-configuration)
    *   [DO use `const` providers](#do-use-const-providers)
    *   [DO use the `.forToken` constructor for
        tokens](#do-use-the-fortoken-constructor-for-tokens)
    *   [PREFER `ClassProvider` to a `Type`](#prefer-classprovider-to-a-type)
*   [Tokens](#tokens)
    *   [DO use typed `OpaqueToken<T>`](#do-use-typed-opaquetokent)
    *   [AVOID using arbitrary tokens](#avoid-using-arbitrary-tokens)
    *   [PREFER `MultiToken<T>` to `multi:
        true`](#prefer-multitokent-to-multi-true)
*   [Injectors](#injectors)
    *   [AVOID using `ReflectiveInjector`](#avoid-using-reflectiveinjector)
*   [Components](#components)
    *   [CONSIDER avoiding using injection to configure individual
        components](#consider-avoiding-using-injection-to-configure-individual-components)
    *   [AVOID specifying providers to give every component a new instance]
        (#avoid-specifying-providers-to-give-every-component-a-new-instance)
*   [Annotations](#annotations)
    *   [PREFER omitting `@Injectable()` where
        possible](#prefer-omitting-injectable-where-possible)

## Providers

### DO use the "named" providers

While not formally deprecated, `provide(...)` and `Provider(...)` require
certain combinations of named optional parameters, and allow combinations that
otherwise will not compile or perform as intended. For example:

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

Instead, use the "named" providers (`ClassProvider`, `ExistingProvider`,
`FactoryProvider`, and `ValueProvider`) in order to make your providers more
readable, in some cases more terse, and use the definition of the class to help
guide the configuration.

**GOOD**:

```dart
const ClassProvider(Foo, useClass: CachedFoo);
const ExistingProvider(Foo, OtherFoo);
const FactoryProvider(Foo, createCachedFoo);
const ValueProvider(Foo, null);
```

### DO use factories for configuration

As part of [avoiding runtime configured providers](#do-use-const-providers), you
may have or desire patterns where dependency injection varies based on some
runtime information, or information that is otherwise not expressable as a
constant. Use `FactoryProvider` instead.

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

It can be tempting to create and configure providers at runtime, either using
`new Provider(...)` or `provide(...)`. While not formally deprecated, runtime
configuration of providers relies on side-effects in your program, and [should
be avoided](#avoid-using-reflectiveinjector).

**BAD**:

```dart
void main() {
  var injector = ReflectiveInjector.resolveAndCreate([
    new ClassProvider(HeroService),
  ]);
}
```

Even if you still rely on this API partially, new providers are highly
recommended to use `const` in order to be able to better injectors in the
future:

**GOOD**:

```dart
void main() {
  var injector = ReflectiveInjector.resolveAndCreate([
    const ClassProvider(HeroService),
  ]);
}
```

### DO use the `.forToken` constructor for tokens

In alignment with [DO use typed `OpaqueToken<T>`](#...) and [DO use the "named"
providers](#...), the `.forToken` constructor should be used in order for type
inference to determine the type of the provider.

**BAD**:

```dart
const appBaseHref = const OpaqueToken<String>('appBaseHref');

// This is created as `Provider<dynamic>`.
const Provider(appBaseHref, useValue: '1234');
```

**GOOD**:

```dart
const appBaseHref = const OpaqueToken<String>('appBaseHref');

// This is created as `Provider<String>`.
const ValueProvider.forToken(appBaseHref, '1234');
```

### PREFER `ClassProvider` to a `Type`

While slightly more terse, the following pattern is not recommended:

```dart
class HeroService {}

const someProviders = const [
  HeroService,
];
```

> In future versions of AngularDart, a new `Module` class will _require_ that
> all providers are explicitly of type (or super-type of) `Provider`, and `Type`
> will not be allowed:
> [https://github.com/dart-lang/angular/issues/543](https://github.com/dart-lang/angular/issues/543).

**GOOD**: Use `ClassProvider` instead.

```dart
class HeroService {}

const someProviders = const [
  const ClassProvider(HeroService),
];
```

## Tokens

### DO use typed `OpaqueToken<T>`

In the past the `OpaqueToken` class was only useful as a convention for
declaring arbitrary tokens (i.e. that were not based on a class `Type`). For
example, you wouldn't want to bind something to `String` (too common), so you'd
create an `OpaqueToken`:

```dart
const appBaseHref = const OpaqueToken('appBaseHref');
```

However, this also meant that it was undocumented (unless manually added with
dartdocs) what the expected _type_ of `APP_BASE_HREF` was (in this case a
`String`). This hurt both developer productivity _and_ the compiler (we don't
know what to expect, so we typed it as `dynamic` always).

**BAD**: Using `OpaqueToken<dynamic>` implicity or explicitly.

```dart
// If not defined, const OpaqueToken(...) is of type <dynamic>.
const appBaseHref = const OpaqueToken('appBaseHref');
```

**GOOD**: Using `OpaqueToken<T>` where `T` is not `dynamic`:

```dart
const appBaseHref = const OpaqueToken<String>('appBaseHref');
```

**GOOD**: Use your own `class` that extends `OpaqueToken<T>`.

Another option is to create your own "custom" token type. It's up to your and
your team whether this is more ergonomic/documenting/clarifying than relying on
a string-based description (`'appBaseHref'`).

```dart
class AppBaseHref extends OpaqueToken<String> {
  const AppBaseHref();
}

// Optional.
const appBaseHref = const AppBaseHref();

// Can be used with .forToken now, for example:
const ValueProvider.forToken(appBaseHref, '/');

// Or as an parameter for injection:
class Comp {
  Comp(@appBaseHref String href) { ... }
}
```

### AVOID using arbitrary tokens

With the older style `Provider(...)` and `provide(...)` it's still type-safe and
permitted to use arbitrary tokens, such as strings, numbers, or even custom
classes. However, these are no longer supported in any form of compile-time
injection (i.e. they only work with runtime-configured injectors like
`ReflectiveInjetor` or `Injector.map`).

**BAD**:

```dart
const Provider('Hello', useValue: 'Hello World');
```

_or_

```dart
class HelloMessage {
  const HelloMessage();
}

// In later configuration.
const Provider(const HelloMessage(), useValue: 'Hello World');
```

**GOOD**: Use a `Type` or `OpaqueToken<T>` instead.

```dart
const helloMessage = const OpaqueToken<String>('Hello');

// In later configuration.
const ValueProvider.forToken(helloMessage, 'Hello World');
```

_or_

```dart
class HelloMessage extends OpaqueToken<String> {
  const HelloMessage();
}
const helloMessage = const HelloMessage();

// In later configuration.
const ValueProvider.forToken(helloMessage, 'Hello World');
```

### PREFER `MultiToken<T>` to `multi: true`

Providers can be created with explicit configuration of `multi: true`, which
means that when they are injected a `List` is returned instead of all tokens
that are configured for that token/type.

**BAD**: Using `multi: true` for this configuration.

```dart
const usPresident = const OpaqueToken<String>('usPresident');

const usPresidentProviders = const [
  const Provider(usPresident, useValue: 'George', multi: true),
  const Provider(usPresident, useValue: 'Abe', multi: true),
];
```

This pattern is _verbose_, _error prone_, and not very self-documenting for
users. You could forget `multi: true`, clients would not know that injecting
`usPresident` gives them a `List`.

**GOOD**: Using `MultiToken` for this configuration instead.

```dart
const usPresidents = const MultiToken<String>('usPresidents');

const usPresidentsProviders = const [
  const ValueProvider.forToken(usPresidents, 'George'),
  const ValueProvider.forToken(usPresidents, 'Abe'),
];
```

As an added bonus, this pattern works better for Dart2; we're able to tell,
statically, in the compiler, that `usPresidents` must return `List<String>` not
a `List<dynamic>`.

## Injectors

### AVOID using `ReflectiveInjector`

While not formally deprecated, `ReflectiveInjector` relies on importing `.dart`
files having side-effects on your program, and negatively effecting tree-shaking
by making all classes and functions annotated with `@Injectable` retained,
regardless of use.

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

### CONSIDER avoiding using injection to configure individual components

Imagine you have a component (`HeroComponent`, or `<hero-component>`) that
requires a model object (`HeroData`) in order to render. You could use
`@Input()` _or_ could use dependency injection.

```dart
class HeroData {
  final bool hasPowerOfFlight;
  final bool vulnerableToGreenGlowingRocks;

  HeroData({
    this.hasPowerOfFlight: false,
    this.vulnerableToGreenGlowingRocks: false,
  });
}
```

**BAD**: Using dependency injection for configuration.

```dart
@Component(
  selector: 'hero-component',
  template: 'I am a HERO, but can I fly: {{canIFly}}',
)
class HeroComponent {
  final HeroData _heroData;

  HeroComponent(this._heroData);

  String get canIFly {
    return _heroData.hasPowerOfFlight ? 'Yes' : 'No';
  }
}
```

While this might _look_ pleasing (i.e. for testing), it means it becomes very
verbose, confusing, and difficult to have multiple hero components with
different configurations - probably not what you want. Use `@Input` instead.

**GOOD**: Using `@Input()` instead for configuration.

```dart
@Component(
  selector: 'hero-component',
  template: 'I am a HERO, but can I fly: {{canIFly}}',
)
class HeroComponent {
  @Input('can-fly')
  bool hasPowerOfFlight = false;

  String get canIFly {
    return hasPowerOfFlight ? 'Yes' : 'No';
  }
}
```

**GOOD**: Using dependency injection when configuring app-wide components.

If you want to, for example, set a property on _all_ `HeroComponent`s, then
dependency injection is perfectly fine (and preferred if you will have many of
them). You could also consider using `@Optional()` in order to avoid making it a
required service.

```dart
abstract class HeroAuthentication {
  bool isLoggedInAsHero(String name);
}

@Component(
  selector: 'hero-component',
  template: '...',
)
class HeroComponent {
  final HeroAuthentication _auth;

  HeroComponent(@Optional() this._auth);

  @Input()
  set name(String name) {
    if (_auth != null && !_auth.isLoggedInAsHero(name)) {
      throw new ArgumentError('Not logged in!');
    }
    // ...
  }
}
```

**GOOD**: Using dependency injection when it makes the component API cleaner.

If some configuration data to a component isn't dynamic consider making that
configuration injectable. This signals to the user that this value can't change
during the lifecycle of the component, and the configuration is available to be
used immediately instead of waiting for certain lifecycle methods. You should
also consider using `@Optional()` in order to avoid making it a required
dependency and thus harder for users to use. Prefer to have reasonable defaults
for these configurations so users of your Component can use it easier.

These components can then be configured with directives that provide the
configuration to allow users to easily support different options on individual
instances, or from the root of the application to change the behavior for all
instances of the component.

```dart
@Component(
  selector: 'number-input',
  template: '...',
)
class NumberInputComponent {
  final NumberFormat _format;
  String text; // What we show to the user.

  NumberInputComponent(@Optional() NumberFormat format) :
      // We are giving it a nice default so it can be used out of the box.
      _format ??= new NumberFormat.decimalPattern();

  @Input()
  set value(num value) {
    text = _format.format(value);
    // ...
  }
  // ...
}

@Directive(
  selector: '[currencyFormat]',
  providers: const [
    const FactoryProvider<NumberFormat>(
      NumberFormat,
      CurrencyFormatDirective.currencyFormat,
    ),
  ],
)
class CurrencyFormatDirective {
  static NumberFormat currencyFormat() => new NumberFormat.simpleCurrency();
}
```

In client template:

```html
<number-input currencyFormat [value]="cost"></number-input>
```

### AVOID specifying providers to give every component a new instance

Unlike the previous practice, where `currentFormat` is specified for _some_
components, it is considered a bad practice to supply the same `providers` to
many components just to avoid using `new`. For example, imagine needing an
instance of the `Cache` class for a component:

**BAD**:

```dart
@Component(
  selector: 'user-list',
  providers: const [
    const ClassProvider(Cache),
  ],
  template: '...'
)
class UserListComponent {
  UserListComponent(Cache cache) {
    // Use a new cache instance per component.
  }
}
```

**GOOD**: Provide a _factory_ class higher up in the application hierarchy:

```dart
@Component(
  selector: 'root',
  providers: const [
    const ClassProvider(CacheFactory),
  ],
  template: '...',
)
class RootComponent {}

@Component(
  selector: 'user-list',
  template: '...',
)
class UserListComponent {
  UserListComponent(CacheFactory cacheFactory) {
    var cache = cacheFactory.createCache();
    // Use a new cache instance per component.
  }
}
```

## Annotations

### PREFER omitting `@Injectable()` where possible

While sometimes not clear, the `@Injectable()` annotation is actually a legacy
feature that is required for runtime-configuration of injectors.

> **NOTE**: For teams or users still utilizing the `bootstrapStatic` (most users
> as of this writing) method or creating `ReflectiveInjector`s at runtime,
> _disregard this part of the guide_, but also know that this pattern is not
> desirable long-term - it increases the code-size of your app somewhat
> dramatically.

**BAD**:

```dart
@Injectable()
class HeroService {}
```

**GOOD**:

```dart
class HeroService {}
```
