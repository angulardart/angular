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
    expect(fixture.text, 'false');
    await fixture.update((_) {
      fixture.rootElement.querySelector('#run').click();
    });
    expect(fixture.text, 'true');
    await fixture.update((_) {
      fixture.rootElement.querySelector('#reset').click();
    });
  });
}

@Component(
  selector: 'example',
  template: '{{ready}}',
)
class ExampleBenchmark implements Benchmark {
  @override
  bool ready = false;
}
