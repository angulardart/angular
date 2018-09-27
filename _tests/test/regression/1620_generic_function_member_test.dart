@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1620_generic_function_member_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('generic function member should return normally', () async {
    final testBed = NgTestBed.forComponent(ng.TestComponentNgFactory);
    final testFixture = await testBed.create();
    expect(testFixture.text, 'foo');
  });
}

class Data {
  final String name;

  Data(this.name);
}

@Component(
  selector: 'generic',
  template: '{{render(value)}}',
)
class GenericComponent<T> {
  @Input()
  String Function(T data) render;

  @Input()
  T value;
}

@Component(
  selector: 'test',
  template: '<generic [render]="render" [value]="value"></generic>',
  directives: [GenericComponent],
  directiveTypes: [Typed<GenericComponent<Data>>()],
)
class TestComponent {
  final value = Data('foo');

  String render(Data data) => data.name;
}
