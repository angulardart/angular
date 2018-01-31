import 'package:_benchmarks/common.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'bootstrap_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should start and stop a benchmark', () async {
    final testBed = new NgTestBed<BenchmarkComponent>().addProviders([
      provide(runBenchmarkOn, useValue: ng.ExampleBenchmarkNgFactory),
    ]);
    final fixture = await testBed.create();
    expect(fixture.text, contains('[false]'));
    await fixture.update((_) {
      fixture.rootElement.querySelector('#run').click();
    });
    expect(fixture.text, contains('[true]'));
    await fixture.update((_) {
      fixture.rootElement.querySelector('#reset').click();
    });
    expect(fixture.text, contains('[false]'));
  });
}

@Component(
  selector: 'example',
  template: '[{{ready}}]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ExampleBenchmark implements Benchmark {
  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;

  bool ready = false;
}
