import 'package:angular/angular.dart';

import 'generated_injectors.template.dart' as ng;

@Injector.generate(const [
  const Provider(Example, useClass: ExamplePrime),

  // TODO(matanl): As soon as ValueProvider is supported, use it.
  const Provider<String>(someMultiToken, useValue: 'A'),
  const Provider<String>(someMultiToken, useValue: 'B'),
])
Injector doGenerate() => ng.doGenerate$Injector();

class Example {}

class ExamplePrime implements Example {}

const someMultiToken = const MultiToken('someMultiToken');
