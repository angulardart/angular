@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'pipe_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support pipes with optional paramters', () async {
    final fixture = await NgTestBed<Example>().create();
    expect(fixture.text, contains('Unpiped: 2014-04-29 06:04:00.000'));
    expect(fixture.text, contains('Piped: Apr 29, 2014'));
  });

  test('should support type arguments on transform return and parameter types',
      () async {
    final testBed = NgTestBed<NopComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, '[1, 2, 3]');
  });

  test('pure pipe should only be invoked when its input changes', () async {
    final testBed = NgTestBed<TestPurePipeComponent>();
    final testFixture = await testBed.create();
    // Initial invocation.
    expect(PurePipe.singleton.invocations, equals(1));
    // Shouldn't be invoked again with the same value to transform.
    await testFixture.update();
    expect(PurePipe.singleton.invocations, equals(1));
    // Should be invoked again with the new value to transform.
    await testFixture.update((component) => component.value = '');
    expect(PurePipe.singleton.invocations, equals(2));
  });
}

@Component(
  selector: 'example',
  template: r'''
    Unpiped:&ngsp;{{now}}
    Piped:&ngsp;{{now | date}}
  ''',
  pipes: [
    DatePipe,
  ],
)
class Example {
  // April 29, 2014, 6:04am.
  final now = DateTime(2014, DateTime.april, 29, 6, 4);
}

@Pipe('nop')
class NopPipe implements PipeTransform {
  List<int> transform(List<int> values) => values;
}

@Component(
  selector: 'nop',
  template: '{{values | nop}}',
  pipes: [NopPipe],
)
class NopComponent {
  final values = [1, 2, 3];
}

@Pipe('pure')
class PurePipe implements PipeTransform {
  static PurePipe singleton = PurePipe._();

  int _invocations = 0;
  int get invocations => _invocations;

  factory PurePipe() => singleton;

  PurePipe._();

  Null transform(_) {
    _invocations++;
    return null;
  }
}

@Component(
  selector: 'test-pure-pipe',
  template: '{{value | pure}}',
  pipes: [PurePipe],
)
class TestPurePipeComponent {
  String value;
}
