import 'package:angular/angular.dart';

import 'generated_injectors.template.dart' as ng;

@Injector.generate(const [
  const Provider(Example, useClass: Example),

  // TODO(matanl): As soon as ValueProvider is supported, use it.
  const Provider<String>(someMultiToken, useValue: 'A'),
  const Provider<String>(someMultiToken, useValue: 'B'),

  // These should be different providers, not the same ones.
  //
  // i.e.
  //   if (identical(token, const OpaqueToken<dynamic
  //      versus
  //   if (identical(token, const OpaqueToken<String
  const Provider<String>(tokenOfDynamic, useValue: 'dynamic'),
  const Provider<String>(tokenOfString, useValue: 'String'),

  // These validate that using `useValue: ...` works with non-literals.
  const Provider(arbitraryToken1, useValue: instanceOfExample),
  const Provider(arbitraryToken2, useValue: instanceOfExamplePrime),
  const Provider(arbitraryToken3, useValue: ExampleTheta.instance),
  const Provider(
    arbitraryToken4,
    useValue: const [
      instanceOfExample,
      instanceOfExamplePrime,
      ExampleTheta.instance,
    ],
  ),
  const Provider(
    arbitraryToken5,
    useValue: const {
      'instanceOfExample': instanceOfExample,
      instanceOfExamplePrime: 'instanceOfExamplePrime',
    },
  ),
])
Injector doGenerate() => ng.doGenerate$Injector();

class Example {
  const Example();
}

class ExamplePrime implements Example {
  const ExamplePrime._withPrivateConstructor();
}

class ExampleTheta implements Example {
  static const instance = const ExampleTheta._withPrivateConstructor();

  const ExampleTheta._withPrivateConstructor();
}

const someMultiToken = const MultiToken('someMultiToken');
const tokenOfDynamic = const OpaqueToken<dynamic>('someToken');
const tokenOfString = const OpaqueToken<String>('someToken');

const arbitraryToken1 = const OpaqueToken('arbitraryToken1');
const arbitraryToken2 = const OpaqueToken('arbitraryToken2');
const arbitraryToken3 = const OpaqueToken('arbitraryToken3');
const arbitraryToken4 = const OpaqueToken('arbitraryToken4');
const arbitraryToken5 = const OpaqueToken('arbitraryToken5');

const instanceOfExample = const Example();
const instanceOfExamplePrime = const ExamplePrime._withPrivateConstructor();
