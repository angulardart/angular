@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'generated_injector_small.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

/// Shows a smaller generated injector.
void main() {
  runApp(ng.createGoldenComponentFactory(), createInjector: doGenerate);
}

@Component(
  selector: 'golden',
  template: '',
)
class GoldenComponent {
  GoldenComponent(Injector i) {
    deopt(i.get);
  }
}

@GenerateInjector([
  Provider(Example, useClass: Example),

  ValueProvider.forToken(someMultiToken, 'A'),
  ValueProvider.forToken(someMultiToken, 'B'),

  // These should be different providers, not the same ones.
  //
  // i.e.
  //   if (identical(token, const OpaqueToken<Object
  //      versus
  //   if (identical(token, const OpaqueToken<String
  ValueProvider.forToken(tokenOfObject, 'Object'),
  ValueProvider.forToken(tokenOfString, 'String'),

  // These validate that using `useValue: ...` works with non-literals.
  ValueProvider.forToken(arbitraryToken1, instanceOfExample),
  ValueProvider.forToken(arbitraryToken2, instanceOfExamplePrime),
  ValueProvider.forToken(arbitraryToken3, ExampleTheta.instance),
  ValueProvider.forToken(
    arbitraryToken4,
    [
      instanceOfExample,
      instanceOfExamplePrime,
      ExampleTheta.instance,
    ],
  ),
  ValueProvider.forToken(
    arbitraryToken5,
    {
      'instanceOfExample': instanceOfExample,
      instanceOfExamplePrime: 'instanceOfExamplePrime',
    },
  ),

  ValueProvider.forToken(XsrfToken(), 'ABC123'),

  FactoryProvider.forToken(tokenOfListOfString, createListOfString),

  FactoryProvider(ExampleOptional, createExampleOptional),
])
final InjectorFactory doGenerate = ng.doGenerate$Injector;

List<String> createListOfString() => ['Hello', 'World'];

ExampleOptional createExampleOptional(@Optional() Example? maybe) {
  return ExampleOptional();
}

class Example {
  const Example();
}

class ExamplePrime implements Example {
  const ExamplePrime._withPrivateConstructor();
}

class ExampleTheta implements Example {
  static const instance = ExampleTheta._withPrivateConstructor();

  const ExampleTheta._withPrivateConstructor();
}

class ExampleOptional implements Example {}

const someMultiToken = MultiToken<String>('someMultiToken');
const tokenOfObject = OpaqueToken<Object>('someToken');
const tokenOfString = OpaqueToken<String>('someToken');
const tokenOfListOfString = OpaqueToken<List<String>>('tokenOfListOfString');

const arbitraryToken1 = OpaqueToken('arbitraryToken1');
const arbitraryToken2 = OpaqueToken('arbitraryToken2');
const arbitraryToken3 = OpaqueToken('arbitraryToken3');
const arbitraryToken4 = OpaqueToken('arbitraryToken4');
const arbitraryToken5 = OpaqueToken('arbitraryToken5');

const instanceOfExample = Example();
const instanceOfExamplePrime = ExamplePrime._withPrivateConstructor();

class XsrfToken extends OpaqueToken<String> {
  const XsrfToken();
}
