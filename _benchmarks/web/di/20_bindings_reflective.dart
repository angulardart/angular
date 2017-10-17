import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/di/create_20_bindings_reflective.template.dart'
    as ng;
import 'package:angular/angular.dart';

void main() {
  bootstrapStatic(
    BenchmarkComponent,
    [
      provide(
        runBenchmarkOn,
        useValue: ng.Create20BindingsReflectiveBenchmarkNgFactory,
      )
    ],
    ng.initReflector,
  );
}
