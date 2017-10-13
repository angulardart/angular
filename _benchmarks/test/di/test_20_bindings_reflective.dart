import 'package:_benchmarks/di/create_20_bindings_reflective.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test(
      'should create 20 DI bindings (reflective)',
      () => new NgTestBed<Create20BindingsReflectiveBenchmark>()
          .create()
          .then((fix) => fix.update((comp) => comp.ready = true)));
}
