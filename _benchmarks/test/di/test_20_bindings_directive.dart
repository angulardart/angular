import 'package:_benchmarks/di/create_20_bindings_directive.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test(
      'should create 20 DI bindings (eager)',
      () => new NgTestBed<Create20BindingsEagerBenchmark>()
          .create()
          .then((fix) => fix.update((comp) => comp.ready = true)));

  test(
      'should create 20 DI bindings (lazy)',
      () => new NgTestBed<Create20BindingsLazyBenchmark>()
          .create()
          .then((fix) => fix.update((comp) => comp.ready = true)));
}
