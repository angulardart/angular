import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/di/create_tree_bindings_directive.template.dart'
    as ng;
import 'package:angular/angular.dart';

void main() {
  bootstrapStatic(
    BenchmarkComponent,
    [
      provide(
        runBenchmarkOn,
        useValue: ng.CreateTreeBindingsBenchmarkNgFactory,
      )
    ],
    ng.initReflector,
  );
}
