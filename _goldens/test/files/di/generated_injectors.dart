import 'package:angular/angular.dart';

import 'generated_injectors.template.dart' as ng;

@GenerateInjector([
  Provider(Example, useClass: Example),

  // TODO(matanl): As soon as ValueProvider is supported, use it.
  Provider<String>(someMultiToken, useValue: 'A'),
  Provider<String>(someMultiToken, useValue: 'B'),

  // These should be different providers, not the same ones.
  //
  // i.e.
  //   if (identical(token, const OpaqueToken<dynamic
  //      versus
  //   if (identical(token, const OpaqueToken<String
  Provider<String>(tokenOfDynamic, useValue: 'dynamic'),
  Provider<String>(tokenOfString, useValue: 'String'),

  // These validate that using `useValue: ...` works with non-literals.
  Provider(arbitraryToken1, useValue: instanceOfExample),
  Provider(arbitraryToken2, useValue: instanceOfExamplePrime),
  Provider(arbitraryToken3, useValue: ExampleTheta.instance),
  Provider(
    arbitraryToken4,
    useValue: [
      instanceOfExample,
      instanceOfExamplePrime,
      ExampleTheta.instance,
    ],
  ),
  Provider(
    arbitraryToken5,
    useValue: {
      'instanceOfExample': instanceOfExample,
      instanceOfExamplePrime: 'instanceOfExamplePrime',
    },
  ),

  Provider(XsrfToken(), useValue: 'ABC123'),
])
final InjectorFactory doGenerate = ng.doGenerate$Injector;

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

const someMultiToken = MultiToken('someMultiToken');
const tokenOfDynamic = OpaqueToken<dynamic>('someToken');
const tokenOfString = OpaqueToken<String>('someToken');

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
