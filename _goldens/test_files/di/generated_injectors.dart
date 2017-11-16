import 'package:angular/angular.dart';

import 'generated_injectors.template.dart' as ng;

@Injector.generate(const [
  const Provider(Example, useClass: ExamplePrime),
])
Injector doGenerate() => ng.doGenerate$Injector();

class Example {}

class ExamplePrime implements Example {}
