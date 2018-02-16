# "Future Proof" AngularDart

* Nothing is ever truly future proof.
* But we can offer hints/tips to keep you on the golden path of support.
* Closer to the golden path = more optimizaitons, more help, happier devs.

## Stop using `SlowComponentLoader`

* Disables the ability to tree-shake code that has a `@Component` annotation.
* Adds significant extra code-size by needing to retain code paths for creation.
* Replacement, `ComponentLoader`, is nearly as idiomatic, and without downsides:
  * [component_loading.md](component_loading.md)

Teams still using `SlowComponentLoader` may need to opt-in to this behavior at
a future point of time, by adding an additional call in `main()` and other
defer-loaded entrypoints in their application:

```dart
import 'main.template.dart' as ng;

void main() {
  ng.initReflector();
}
```

## Stop using `ReflectiveInjector`

* Disables the ability to tree-shake code that has an `@Injectable` annotation.
* Adds significant extra code-size to support the runtime injector model.
* **No replacement available yet**. Will update this document once.

Teams still using `ReflectiveInjector` may need to either opt-in to this
behavior at a future point of time (by adding an additional call in `main()`
and other defer-loaded entrypoints):

```dart
import 'main.template.dart' as ng;

void main() {
  ng.initReflector();
}
```

... or it's also possible that a more long-term, `RuntimeProvider`, will be used
to provide some API compatibility without needing `initReflector`:

```dart
final injector = new Injector.slowReflective([
  provide(Foo, useValue: new Foo()),
  provide(Foo, useFactory: (Bar bar) => new Foo(bar), deps: [Bar]),
]);
```

Notice that `useClass` would no longer be supported, only manually specifying
a factory function, _and_ manually specifying a `deps: [ ... ]` list - we would
no longer store this information as part of our code generation steps.

## Type `OpaqueToken` and `MultiToken` wherever possible

i.e. `OpaqueToken<String>(...)` instead of `OpaqueToken(...)`.

## Use the typed {`Class`|`Existing`|`Factory`|`Value`}`Provider` types

`const Provider(Foo, useClass: FooImpl)` to `const ClassProvider(Foo, FooImpl)`

`const Provider(Foo, useExisting: Bar)` to `const ExistingProvider(Foo, Bar)`

`const Provider(Foo, useFactory: createFoo)` to `const FactoryProvider(Foo, createFoo)`

`const Provider(Foo, useValue: 5)` to `const ValueProvider(Foo, 5)`

When binding to an `OpaqueToken` or `MultiToken`, use a `forToken` constructor:

```dart
const usPresidents = const MultiToken<String>('usPresidents');

const usPresidentsProviders = const [
  const ValueProvider.forToken(usPresidents, 'George Washington'),
  const ValueProvider.forToken(usPresidents, 'Abraham Lincoln'),
];
```

## Use `MultiToken` instead of `multi: true`

**BEFORE**:

```dart
const appValidators = const OpaqueToken<AppValidator>('appValidators');

const providers = const [
  const Provider(appValidators, useValue: validatorA, multi: true),
  const Provider(appValidators, useValue: validatorB, multi: true),
];
```

**AFTER**:

```dart
const appValidators = const MultiToken<AppValidator>('appValidators');

const providers = const [
  const Provider(appValidators, useValue: validatorA),
  const Provider(appValidators, useValue: validatorB),
];
```
