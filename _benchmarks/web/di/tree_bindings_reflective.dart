import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/di/create_tree_bindings_reflective.template.dart'
    as benchmark;

void main() {
  // Required for ReflectiveInjector.
  benchmark.initReflector();
  runBenchmarkApp(benchmark.CreateTreeBindingsReflectiveBenchmarkNgFactory);
}
