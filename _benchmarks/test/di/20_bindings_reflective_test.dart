import 'package:_benchmarks/di/create_20_bindings_reflective.template.dart'
    as ng_comp;
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '20_bindings_reflective_test.template.dart' as ng_generated;

void main() {
  // Required: We use ReflectiveInjector.
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should create 20 DI bindings (reflective)', () async {
    final testBed = NgTestBed.forComponent(
      ng_comp.Create20BindingsReflectiveBenchmarkNgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((comp) => comp.ready = true);
  });
}
