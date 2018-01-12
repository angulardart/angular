import 'package:angular/angular.dart';

import 'generated_injectors.template.dart' as ng;

@Injector.generate(const [
  const Provider(Example, useClass: ExamplePrime),

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
])
Injector doGenerate() => ng.doGenerate$Injector();

class Example {}

class ExamplePrime implements Example {}

const someMultiToken = const MultiToken('someMultiToken');
const tokenOfDynamic = const OpaqueToken<dynamic>('someToken');
const tokenOfString = const OpaqueToken<String>('someToken');
