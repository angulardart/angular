import 'package:_benchmarks/di/create_tree_bindings_reflective.template.dart'
    as ng;
import 'package:angular/angular.dart';

void main() {
  bootstrapStatic(
    ng.CreateTreeBindingsReflectiveBenchmark,
    [],
    ng.initReflector,
  );
}
