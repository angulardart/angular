# Dependency Injection FAQ


Dependency Injection in AngularDart has several significant technical and
pattern implications that are not trivial to work around or change without a
large concerted effort (and potentially breaking changes).

Below are some of the most common questions received from users of AngularDart
regarding dependency injection, and the canonical answers for those questions.

## Overview

In general, most everything can be explained by giving a simple technical
overview of how dependency injection is implemented, and why it is implemented
that way. You can think of dependency injection as a `HashMap<K, V>`, where:

* `K` is the token used for injection (a class `Type` or `OpaqueToken`).
* `V` is the value to be provided when `K` is requested.

For example:

```dart
class Service {}

// This API doesn't exist as-is, it's just an example.
createInjector({
  Service: Service(),
});
```

So, calling `injector.get(Service)` is sort of like `hashMap[Service]` (with the
main difference that a runtime error is thrown if `Service` is missing, instead
of `null` being returned).

Of course, not all providers can be satisfied by a constant value; they may need
_other_ providers and values in order to create a more complex object. So in
truth, the implementation is more like the following:

* `K` is the token used for injection (a class `Type` or `OpaqueToken`).
* `V` is a `V Function<K, V>(K key, Injector current)` callback, where the
  function is executed the first time the _key_ is requested (and subsequent
  requests use the same cached instance, i.e. the singleton pattern).

For example:

```dart
class CoffeeMachine {
  CoffeeMachine(Electricity e);
}

class Electricity {}

createInjector({
  CoffeeMachine: (key, injector) {
    return CoffeeMachine(injector.get(Electricity));
  },
  Electricity: (key, injector) => Electricity(),
});
```

There you go, we've implemented dependency injection!

Now, it would be both verbose and error-prone to have a single `HashMap` for
your entire application (especially among large distributed teams, or parts of
your application that have nothing to do with each-other). So AngularDart
supports _linking_ the hash maps (not to be confused with `LinkedHashMap`), that
is, an injector can _delegate_ to a single _parent_ injector for missing
providers:

* `K` is the token used for injection (a class `Type` or `OpaqueToken`).
* `V` is a `V Function<K, V>(K key, Injector current, Injector parent)`.

For example:

```dart
class CoffeeMachine {
  CoffeeMachine(Electricity e);
}

createInjector({
  CoffeeMachine: (key, injector, parent) {
    // We don't provide 'Electricity', so we assume it comes from a parent.
    return CoffeeMachine(parent.get(Electricity));
  },
}, someParentInjector);
```

... and ultimately, injectors (and the backing `HashMap`s) form a tree. As you
can see, dependency injection is implemented fairly simply today - this is
intentional in order to make understanding it (and developing it) simpler. It's
possible to make a more complex implementation with more features, but then it
will deviate sharply from a simple set of linked hash maps.

> **NOTE**: This document is not a _we will never add new features_ testament,
> but instead a realistic overview of the challenges of adding requested
> features to the DI system without breaking other implications.

## Why can't I be told, at compile-time, if providers are missing?

AngularDart unlike the previous AngularDart 1.0 or AngularJS 1.x, is a
mostly _static_ web framework. What that means is that _most_ user and template
code is declared ahead-of-time, in a combination of HTML templates and Dart
metadata annotations.

However, some parts of AngularDart are still dynamic, mostly at user-request
(not a technical requirement). For example, application bootstrap is partially
dynamic:

```dart
main() {
  runApp(
    generated.RootComponentNgFactory,
    createInjector: generated.RootInjector$Injector,
  );
}
```

In Dart, there _is_ a technical limitation to analyzing imperative code,
including function bodies, to use for code generation (the only tools that are
"allowed" to do this are the Dart->JS compilers). What that means is we cannot
tell what `Injector` is being used to create `RootComponent`'s template, so
we don't know what `providers` will or will not be missing.

So, we'd need a way of _completely_ static app initialization; that is,
you would need to statically declare your root component _and_ your root
services. For example:

```dart
@Application(createInjector: const [ ... ])
ComponentRef<RootComponent> Function runRootApp() = generated.$runRootApp;
```

_This is certainly possible, but not provided today. However, keep reading._

Assuming this feature was implemented and teams used it (for example, this would
prohibit any runtime configuration of dependency injection, at all), then the
next issue is that not all components are created (or known) statically.

Anytime you use `ComponentLoader` (or related APIs), again, there are
imperative user-defined function bodies that change the dependency injection
tree in ways that we can't statically inspect:

```dart
class ContainerComponent {
  ContainerComponent(ComponentLoader loader) {
    // We can't, statically, look at ChildComponent (and all of ChildComponent's
    // children, recursively) and see if the providers would be satisfied by the
    // current component (and all of it's ancestry of injectors).
    loader.loadComponent(ChildComponentNgFactory);
  }
}
```

This problem is not easily surmountable. Teams that could build the entire app
without `ComponentLoader` (or any widgets that use `ComponentLoader`, of which
there are currently _many_) _could_ get static DI errors, but even a single use
of dynamic component loading would give many false positives/negatives depending
on how the errors were implemented.

## Why can't I require a provider?

A frequent request is asking "how do I _require_ a provider to be provided by
a child component and/or injector". The simplest answer here is this is already
built-in - anytime you declare a dependency on something that is not provided
it is required:

```dart
class Service {
  Service(HttpClient _);
}

@Component(
  providers: [
    // Implicitly, this is declaring 'HttpClient' is now required.
    ClassProvider(Service),
  ],
)
```

Even above, _required_ isn't strictly true. As long as nobody requests the
`Service` class, it's totally fine to not provide an `HttpClient`. For example,
imagine that some child component overrides `Service` to provide `MockService`;
in that case, there is no longer a requirement to have an `HttpClient`.

## Why can't I prevent a provider from being overridden?

This is a similar question to asking "why can't I prevent a `HashMap` key from
being written over". You _could_, but definitely not statically, which means
that users would run into a runtime error in some cases (but not others).

Part of the issue with this request is it fundamentally conflicts with the goal
of dependency injection in Angular, which is being able to override providers.
Lets look at an example of dependency injection _without_ a framework:

```dart
class CoffeeMachine {
  final Electricity _electricity;
  CoffeeMachine(this._electricity);
}

void main() {
  var workingMachine = CoffeeMachine(Electricity());
  var unpluggedMachine = CoffeeMachine(NoopElectricity());
}
```

Imagine you wanted to make `Electricity` _not_ be overridable. Well, in that
case you would simply remove it as a parameter to `CoffeeMachine` and use `new`
(or another pattern, like a static singleton):

```dart
class CoffeeMachine {
  final _electricity = Electricity();
}

void main() {
  var workingMachine = CoffeeMachine();
}
```

This problem is hit most commonly when [dependency injection is overused][1],
which is currently an _anti-pattern_ according to the dependency injection
style guide.

[1]: ../effective/dependency-injection.md#components

It's certainly _possible_ to think of various different runtime mechanisms to
prevent overriding a provider, but like the above questions they will all likely
either have many false positives/negatives, user confusion, or further
complicate dependency injection.

## How can I override a provider in a component for testing?

### Overriding providers

A common pattern in component-driven design is to include dependencies in a
`@Component`-annotated `class` that are required by the component or its
children (in the template).

For example, assume you are creating the next great "Google Play"-like frontend
where you have a _shopping_ view (where most users interact 95% of the time)
and a _checkout_ view (which is lazily loaded on demand, and includes services
for checking out with a credit card):

```dart
// shopping.dart
@Component(
  selector: 'shopping-view',
  providers: [ shoppingModule ] ,
  template: '...',
)
class ShoppingView {}
```

```dart
// checkout.dart
@Component(
  selector: 'checkout-view',
  providers: [
    ClassProvider(CreditCardProcessor, useClass: GoogleWallet),
  ],
  template: '...',
)
class CheckoutView {}
```

Great! You can now _defer_ load `CheckoutView`, and it will load itself and the
`GoogleWallet` service on-demand (versus by default, when most users are just
browsing and don't need it).

But in a test, you don't want to use `GoogleWallet`... What do you do?

### Creating a test directive

You can create a `@Directive` and use it to _annotate_ your view class during
a test to override certain providers. Here for the above example lets add a
simple `StubCreditCardProcessor` that _always_ just "succeeds":

```dart
@Injectable()
class StubCreditCardProcessor implements CreditCardProcessor {
  @override
  Future<bool> charge(double amount) async => true;
}
```

Now lets wire it up:

```dart
@Directive(
  selector: '[override]',
  providers: [
    ClassProvider(CreditCardProcessor, useClass: StubCreditCardProcessor),
  ],
)
class OverrideDirective {}

@Component(
  selector: 'test-checkout-view',
  directives: [
    CheckoutView,
    OverrideDirective,
  ],
  template: '<checkout-view override></checkout-view>',
)
class TestCheckoutView {}
```

You can now create and test `TestCheckoutView`: it will create an instance of
the `CheckoutView` component, but it and its children will get
`StubCreditCardProcessor` whenever `CreditCardProcessor` is injected!
