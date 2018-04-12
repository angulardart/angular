import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/di/create_20_bindings_reflective.template.dart'
    as benchmark;

void main() {
  // Required for ReflectiveInjector.
  benchmark.initReflector();
  runBenchmarkApp(benchmark.Create20BindingsReflectiveBenchmarkNgFactory);
}
