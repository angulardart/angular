import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/di/create_tree_bindings_directive.template.dart'
    as benchmark;

void main() {
  runBenchmarkApp(benchmark.CreateTreeBindingsBenchmarkNgFactory);
}
