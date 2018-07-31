import 'package:_benchmarks/common.dart';
import 'package:_benchmarks/common.template.dart' as common;
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'bootstrap_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should start and stop a benchmark', () async {
    final testBed = NgTestBed.forComponent(
      common.BenchmarkComponentNgFactory,
      rootInjector: ([i]) {
        return Injector.map(
          {runBenchmarkOn: ng.ExampleBenchmarkNgFactory},
          i,
        );
      },
    );
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
)
class ExampleBenchmark implements Benchmark {
  @override
  void start() => ready = true;

  @override
  void reset() => ready = false;

  bool ready = false;
}
