import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/di/create_20_bindings_directive.template.dart'
    as benchmark;

void main() {
  runBenchmarkApp(benchmark.Create20BindingsLazyBenchmarkNgFactory);
}
