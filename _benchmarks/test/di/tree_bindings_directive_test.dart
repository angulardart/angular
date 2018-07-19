import 'package:_benchmarks/di/create_tree_bindings_directive.template.dart'
    as ng_generated;
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should create 20 DI bindings (reflective)', () async {
    final testBed = NgTestBed.forComponent(
      ng_generated.CreateTreeBindingsBenchmarkNgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((comp) => comp.ready = true);
  });
}
