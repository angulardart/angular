@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1669_pipe_argument_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should pass a pipe with multiple arguments as argument to function',
      () async {
    final testBed = NgTestBed.forComponent(ng.TestThreeInterpolationNgFactory);
    final testFixture = await testBed.create(
      beforeChangeDetection: (component) {
        component
          ..prefix = '('
          ..suffix = ')'
          ..value = 'Hello';
      },
    );
    expect(testFixture.text, contains('(Hello).'));
    expect(testFixture.text, contains('(Hello)!'));
  });
}

@Pipe('test')
class TestPipe implements PipeTransform {
  String transform(
    String value,
    String prefix,
    String suffix, [
    String punctuation = '.',
  ]) =>
      '$prefix$value$suffix$punctuation';
}

@Component(
  selector: 'test',
  template: r'''
    {{function(value | test:prefix:suffix)}}
    {{function(value | test:prefix:suffix:"!")}}
  ''',
  pipes: [TestPipe],
)
class TestThreeInterpolation {
  String prefix;
  String suffix;
  String value;

  String function(String value) => value;
}
