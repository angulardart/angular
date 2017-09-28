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
  ng.enableSlowComponentLoader();
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
  ng.enableReflectiveInjector();
}
```

... or it's also possible that a more long-term, `RuntimeProvider`, will be used
to provide some API compatibility without needing `enableReflectiveInjector`:

```dart
final injector = new Injector.fromRuntime([
  provide(Foo, useValue: new Foo()),
  provide(Foo, useFactory: (Bar bar) => new Foo(bar), deps: [Bar]),
]);
```

Notice that `useClass` would no longer be supported, only manually specifying
a factory function, _and_ manually specifying a `deps: [ ... ]` list - we would
no longer store this information as part of our code generation steps.
