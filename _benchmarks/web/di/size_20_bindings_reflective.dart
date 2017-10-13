import 'package:_benchmarks/di/create_20_bindings_reflective.template.dart'
    as ng;
import 'package:angular/angular.dart';

void main() {
  bootstrapStatic(
    ng.Create20BindingsReflectiveBenchmark,
    [],
    ng.initReflector,
  );
}
