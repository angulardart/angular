# Overriding providers

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
  providers: const [ shoppingModule ] ,
  template: '...',
)
class ShoppingView {}
```

```dart
// checkout.dart
@Component(
  selector: 'checkout-view',
  providers: const [
    const Provider(CreditCardProcessor, useClass: GoogleWallet),
  ],
  template: '...',
)
class CheckoutView {}
```

Great! You can now _defer_ load `CheckoutView`, and it will load itself and the
`GoogleWallet` service on-demand (versus by default, when most users are just
browsing and don't need it).

But in a test, you don't want to use `GoogleWallet`... What do you do?

## Creating a test directive

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
  providers: const [
    const Provider(CreditCardProcessor, useClass: StubCreditCardProcessor),
  ],
)
class OverrideDirective {}

@Component(
  selector: 'test-checkout-view',
  directives: const [
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
