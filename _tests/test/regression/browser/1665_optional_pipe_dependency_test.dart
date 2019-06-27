@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import '1665_optional_pipe_dependency_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('a missing @Optional() pipe dependency does not throw', () async {
    var testBed = NgTestBed.forComponent(ng.TestComponentNgFactory);
    expect(testBed.create(), completes);
  });
}

abstract class TestService {}

@Pipe('test')
class TestPipe extends PipeTransform {
  TestPipe(@Optional() TestService _);

  dynamic transform(dynamic value) => value;
}

@Component(
  selector: 'test',
  template: '{{value | test}}',
  pipes: [TestPipe],
)
class TestComponent {
  var value = 'Hello world!';
}
