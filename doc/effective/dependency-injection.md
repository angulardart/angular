# Effective AngularDart: Dependency Injection


There are many different ways to use AngularDart to provide and utilize
dependency injection throughout your application, components, and services. This
guide is meant to serve as a **development tool** and to help push **best
practices** from the developers of the AngularDart framework.

## Providers

### DO use "named" providers

While not formally deprecated, `provide(...)` and `Provider(...)` require
certain combinations of named optional parameters and allow combinations that
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
runtime information or information that is otherwise not expressable as a
constant. Use `FactoryProvider` instead.

**BAD**:

```dart
Provider bindUser(Flags flags) {
  if (flags.isAdminUser) {
    return ClassProvider(User, useClass: AdminUser);
  }
  return ClassProvider(User, useClass: RegularUser);
}
```

**GOOD**:

```dart
const provideUser = FactoryProvider(User, createUserFromFlags);

User createUserFromFlags(Flags flags) {
  return flags.isAdminUser ? AdminUser() : RegularUser();
}
```

The value provided is still dynamically determined, but the key (`User`) can be
determined at compile time.

### AVOID `ValueProvider` for complex types

Similar to [DO use factories for
configuration](#do-use-factories-for-configuration), `ValueProvider` is poorly
suited for complex `const` objects or objects where the reified type argument(s)
are significant.

**BAD**:

There is an existing pattern, `MultiToken`, exactly for this purpose:

```dart
const adminUsers = OpaqueToken<List<String>>('adminUsers');
const provideNames = ValueProvider.forToken(adminUsers, ['Maeve', 'Dolores']);
```

**GOOD**:

```dart
const adminUsers = MultiToken<String>('adminUsers');
const provideNames = [
  ValueProvider.forToken(adminUsers, 'Maeve'),
  ValueProvider.forToken(adminUsers, 'Dolores'),
];
```

**BAD**:

```dart
class CampaignValue {
  final String name;
  final int campaignId;
  final List<String> metadata;

  const CampaignValue({this.name, this.campaignId, this.metadata});
}

const provideCampaignValue = ValueProvider(CampaignValue, CampaignValue(
  name: 'Westworld',
  campaignId: 1001,
  metadata: [
    'VALLEY_BEYOND',
  ],
));
```

**GOOD**:

Using a custom factory function is better than relying on AngularDart to
understand the correct way(s) to re-create your custom `const` objects:

```dart
const provideCampaignValue = FactoryProvider(CampaignValue, createCampaign);

CampaignValue createCampaign() {
  return const CampaignValue(
    name: 'Westworld',
    campaignId: 1001,
    metadata: [
     'VALLEY_BEYOND',
    ],
  );
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

In alignment with [DO use typed `OpaqueToken<T>`](#do-use-typed-opaquetokent) and
[DO use "named" providers](#do-use-named-providers), the `.forToken` constructor should be used in order for type
inference to determine the type of the provider.

**BAD**:

```dart
const appBaseHref = OpaqueToken<String>('appBaseHref');

// This is created as `Provider<dynamic>`.
const Provider(appBaseHref, useValue: '1234');
```

**GOOD**:

```dart
const appBaseHref = OpaqueToken<String>('appBaseHref');

// This is created as `Provider<String>`.
const ValueProvider.forToken(appBaseHref, '1234');
```

### PREFER `ClassProvider` to a `Type`

While slightly more terse, the following pattern is not recommended:

```dart
class HeroService {}

const someProviders = [
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

const someProviders = [
  ClassProvider(HeroService),
];
```

### PREFER to spread lists of Providers with the spread operator

As of Dart 2.5, the new [spread operator] can be used in const expressions, for
example in `@Component` annotations. This can make Provider lists more readable,
and can allow them to be properly typed, as `List<Provider>`. Long lists of
Providers are especially easier to scan for "nested" lists of Providers when
they are spread.

[spread operator]: https://dart.dev/guides/language/language-tour#spread-operator

**BAD**: Mixing individual Providers with dynamic lists (of Providers and of
lists of Providers, ...):

```dart
@Component(
  selector: 'hero-component',
  directives: [MaterialSelectComponent, MaterialSelectItemComponent, NgIf],
  providers: [
    windowBindings,
    domServiceBinding,
  ]
)
```

**GOOD**: Spreading lists of bindings:

```dart
@Component(
  selector: 'hero-component',
  directives: [MaterialSelectComponent, MaterialSelectItemComponent, NgIf],
  providers: <Provider>[
    ...windowBindings,
    domServiceBinding,
  ]
)
```

Even when a list of Providers includes only the elements found in another single
list of Providers, it is more readable and understandable to declare a new list
literal, and spread the elements of the other singe list.

**BAD**: Referencing a bare list of Providers:

```dart
@Component(
  selector: 'hero-component',
  providers: autoSuggestInputBindings,
)
```

**GOOD**: Spreading a list of Providers into a new list literal:

```dart
@Component(
  selector: 'hero-component',
  providers: [...autoSuggestInputBindings],
)
```

## Tokens

### DO use typed `OpaqueToken<T>`

In the past the `OpaqueToken` class was only useful as a convention for
declaring arbitrary tokens (i.e. that were not based on a class `Type`). For
example, you wouldn't want to bind something to `String` (too common), so you'd
create an `OpaqueToken`:

```dart
const appBaseHref = OpaqueToken('appBaseHref');
```

However, this also meant that it was undocumented (unless manually added with
dartdocs) what the expected _type_ of `APP_BASE_HREF` was (in this case a
`String`). This hurt both developer productivity _and_ the compiler (we don't
know what to expect, so we typed it as `dynamic` always).

**BAD**: Using `OpaqueToken<dynamic>` implicity or explicitly.

```dart
// If not defined, OpaqueToken(...) is of type <dynamic>.
const appBaseHref = OpaqueToken('appBaseHref');
```

**GOOD**: Using `OpaqueToken<T>` where `T` is not `dynamic`:

```dart
const appBaseHref = OpaqueToken<String>('appBaseHref');
```

**GOOD**: Use your own `class` that extends `OpaqueToken<T>`.

Another option is to create your own "custom" token type. It's up to you and
your team whether this is more ergonomic/documenting/clarifying than relying on
a string-based description (`'appBaseHref'`).

```dart
class AppBaseHref extends OpaqueToken<String> {
  const AppBaseHref();
}

// Optional.
const appBaseHref = AppBaseHref();

// Can be used with .forToken now, for example:
const ValueProvider.forToken(appBaseHref, '/');

// Or as a parameter for injection:
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
const Provider(HelloMessage(), useValue: 'Hello World');
```

**GOOD**: Use a `Type` or `OpaqueToken<T>` instead.

```dart
const helloMessage = OpaqueToken<String>('Hello');

// In later configuration.
const ValueProvider.forToken(helloMessage, 'Hello World');
```

_or_

```dart
class HelloMessage extends OpaqueToken<String> {
  const HelloMessage();
}
const helloMessage = HelloMessage();

// In later configuration.
const ValueProvider.forToken(helloMessage, 'Hello World');
```

### PREFER `MultiToken<T>` to `multi: true`

Providers can be created with explicit configuration of `multi: true`, which
means that when they are injected a `List` is returned instead of all tokens
that are configured for that token/type.

**BAD**: Using `multi: true` for this configuration.

```dart
const usPresident = OpaqueToken<List<String>>('usPresident');

const usPresidentProviders = [
  Provider(usPresident, useValue: 'George', multi: true),
  Provider(usPresident, useValue: 'Abe', multi: true),
];
```

This pattern is _verbose_, _error prone_, and not very self-documenting for
users. You could forget `multi: true`, clients would not know that injecting
`usPresident` gives them a `List`.

**GOOD**: Using `MultiToken` for this configuration instead.

```dart
const usPresidents = MultiToken<String>('usPresidents');

const usPresidentsProviders = [
  ValueProvider.forToken(usPresidents, 'George'),
  ValueProvider.forToken(usPresidents, 'Abe'),
];
```

As an added bonus, this pattern works better for Dart2; we're able to tell,
statically, in the compiler, that `usPresidents` must return `List<String>` not
a `List<dynamic>`.

## Injectors

### AVOID using `ReflectiveInjector`

While not formally deprecated, `ReflectiveInjector` relies on importing `.dart`
files having side-effects on your program and negatively affecting tree-shaking
by making all classes and functions annotated with `@Injectable` retained,
regardless of use.

**BAD**:

```dart
void main() {
  var injector = ReflectiveInjector.resolveAndCreate([
    ClassProvider(HeroService),
  ]);
}
```

AngularDart gives a few alternative options when creating injectors.

**GOOD**: Use `Injector.map` to create a simple dynamic injector.

```dart
void main() {
  var injector = Injector.map({
    HeroService: HeroService(),
  });
  // ...
}
```

**GOOD**: Use `providers: [ ... ]` in `@Component` or `@Directive`.

```dart
@Component(
  selector: 'comp',
  providers: [
    ClassProvider(HeroService),
  ],
)
class Comp {}
```

**GOOD**: Use `@GenerateInjector` to generate an injector at compile-time.

```dart
// assume you are currently in file.dart
import 'file.template.dart' as ng;

@GenerateInjector([
  ClassProvider(HeroService),
])
final InjectorFactory heroInjector = ng.heroInjector$Injector;
```

**GOOD**: For migration purpoess, you could use
[`ReflectiveInjector.resolveStaticAndCreate`][ri-static] instead of
`resolveAndCreate`. This is meant to be a _transitional_ API before you switch
to another injector. With `resolveStaticAndCreate`, any `ClassProvider` or a
`FactoryProvider` without `deps: [ ... ]` will be rejected at runtime. This
allows you to start using `runApp` (and remove `initReflector()`) without
removing _every_ instance of `ReflectiveInjector` use.

[ri-static]: https://cs.corp.google.com/piper///depot/google3/third_party/dart_src/angular/angular/lib/src/di/injector/runtime.dart?sq=package:piper+file://depot/google3+-file:google3/experimental&rcl=218100503&g=0&l=45-82

### PREFER `.provideType` or `.provideToken` to `.get`

When using the `Injector` API directly (or APIs that provide access to
`Injector`), use `.provideType` or `.provideToken` in order to avoid accidental
dynamic calls, and improve the performance of DDC and Dart2JS.

**BAD**:

```dart
void example(Injector injector) {
  var dog = injector.get(Dog);
  dog.bark(); // Dynamic call, "dog" is dynamic.
  dog.meow(); // Runtime error, NoSuchMethod.
}
```

**GOOD**: Use `.provideType<T>(Type token)`.

```dart
void example(Injector injector) {
  var dog = injector.provideType<Dog>(Dog); // Omitting <Dog> is a runtime error.
  dog.bark(); // Static call.
  dog.meow(); // Static error.
}
```

You can also infer `<T>` in some cases by relying on existing types:

```dart
void example(Injector injector) {
  giveMeADog(injector.provideType(Dog)); // Inferred as .provideType<Dog>
}

void giveMeADog(Dog dog) {}
```

**GOOD**: Use `.provideToken` for `OpaqueToken`s.

```dart
const xsrfToken = OpaqueToken<String>('xsrfToken');

void example(Injector injector) {
  var token = injector.provideToken(xsrfToken); // inferred as <String>
}
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
      throw ArgumentError('Not logged in!');
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
  providers: [
    FactoryProvider<NumberFormat>(
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
  providers: [
    ClassProvider(Cache),
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
  providers: [
    ClassProvider(CacheFactory),
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

### PREFER to spread lists of directives with the spread operator

As of Dart 2.5, the new spread syntax can be used in const expressions, for
example in `@Component` annotations. This can make directive lists more
readable. Long lists of directives are especially easier to scan for "nested"
lists of directives when they are spread.

**BAD**: Mixing individual directives with lists:

```dart
@Component(
  selector: 'hero-component',
  directives: [
    formDirectives,
    AutoFocusDirective,
    MaterialButtonComponent,
    MaterialIconComponent,
    materialInputDirectives,
    MaterialMultilineInputComponent,
    MaterialInputAutoSelectDirective,
    materialNumberInputDirectives,
    MaterialPaperTooltipComponent,
  ],
)
```

**GOOD**: Spreading included lists of directives:

```dart
@Component(
  selector: 'hero-component',
  directives: [
    ...formDirectives,
    AutoFocusDirective,
    MaterialButtonComponent,
    MaterialIconComponent,
    ...materialInputDirectives,
    MaterialMultilineInputComponent,
    MaterialInputAutoSelectDirective,
    ...materialNumberInputDirectives,
    MaterialPaperTooltipComponent,
  ],
)
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

## Testing

### AVOID initialization code outside of Angular

When writing classic unit tests, it is often compelling to use `setUp` or to
create and reuse helper functions for initializing services or other complex
dependencies:

```dart
void main() {
  HttpService service;
  Analytics analytics;

  // Every test('...', () { ... }) can re-use this initialization logic.
  setUp(() {
    service = FakeHttpService();
    analytics = Analytics(service);
  });

  test('should not retry on a 404', () async {
    service.respondWith(404);
    await analytics.trackHit();
    expect(service.attempts, 1);
  });
}
```

**BAD**: Passing pre-initialized complex services

In Angular, this pattern causes a very fundamental problem - nothing was created
within our `Zone`, so the test framework is not able to tell when asynchronous
code has started and stopped executing:

```dart
void main() {
  HttpService service;
  Analytics analytics;

  setUp(() {
    service = FakeHttpService();
    analytics = Analytics(service);
  });

  test('should display the current progress status', () async {
    // There are multiple patterns for creating a test bed, yours may not match.
    final testBed = NgTestBed.forComponent(
      TestProgressComponentNgFactory,
      rootInjector: ([parent]) {
        return Injector.map({
          Analytics: analytics,
        }, parent);
      },
    );
    final fixture = await testBed.create();

    await expectProgressIndicator(0.0);
    await testBed.update(() => service.sendProgress(10.0));
    await expectProgressIndictator(10.0);
  });
}
```

See the problem? There is no guarantee that anything `Analytics` executes is
tracked by the test framework, so it's possible that the UI will not update.
This often leads to frustrating behavior, or having to wait arbitrary amounts
of time to "simulate" asynchronous work (which is flaky and slow).

**GOOD**: Create complex services within `@Component.providers`:

```dart
void main() {
  HttpService service;

  test('should display the current progress status', () async {
    // There are multiple patterns for creating a test bed, yours may not match.
    final testBed = NgTestBed.forComponent(
      TestProgressComponentNgFactory,
    );
    final fixture = await testBed.create(
      beforeComponentCreated: (injector) {
        service = injector.provide(HttpService);
      },
    );

    await expectProgressIndicator(0.0);
    await testBed.update(() => service.sendProgress(10.0));
    await expectProgressIndictator(10.0);
  });
}

@Component(
  selector: 'test',
  directives: [
    ProgressComponent,
  ],
  providers: [
    ClassProvider(HttpService, useClass: FakeHttpService),
    ClassProvider(Analytics),
  ],
)
class TestProgressComponent {
  // ...
}
```

This does the same thing, but creates and manages the services just like an app!
