import 'package:angular/angular.dart';

import 'generated_injectors.template.dart' as ng;

@Injector.generate(const [
  const Provider(Example, useClass: ExamplePrime),
  const Provider(someMultiToken, useValue: 'A'),
  const Provider(someMultiToken, useValue: 'B'),
])
Injector doGenerate() => ng.doGenerate$Injector();

class Example {}

class ExamplePrime implements Example {}

const someMultiToken = const MultiToken('someMultiToken');
