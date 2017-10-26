@Tags(const ['codegen'])
@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support pipes with optional paramters', () async {
    final fixture = await new NgTestBed<Example>().create();
    expect(fixture.text, contains('Unpiped: 2014-04-29 06:04:00.000'));
    expect(fixture.text, contains('Piped: Apr 29, 2014'));
  });

  test('should support type arguments on transform return and parameter types',
      () async {
    final testBed = new NgTestBed<NopComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, '[1, 2, 3]');
  });
}

@Component(
  selector: 'example',
  template: r'''
    Unpiped:&ngsp;{{now}}
    Piped:&ngsp;{{now | date}}
  ''',
  pipes: const [
    DatePipe,
  ],
)
class Example {
  // April 29, 2014, 6:04am.
  final now = new DateTime(2014, DateTime.APRIL, 29, 6, 4);
}

@Pipe('nop')
class NopPipe {
  List<int> transform(List<int> values) => values;
}

@Component(
  selector: 'nop',
  template: '{{values | nop}}',
  pipes: const [NopPipe],
)
class NopComponent {
  final values = [1, 2, 3];
}
