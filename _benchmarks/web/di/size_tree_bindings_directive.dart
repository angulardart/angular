import 'package:_benchmarks/di/create_tree_bindings_directive.template.dart'
    as ng;
import 'package:angular/angular.dart';

void main() {
  bootstrapStatic(
    ng.CreateTreeBindingsBenchmark,
    [],
    ng.initReflector,
  );
}
