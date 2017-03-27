@Tags(const ['codegen'])
@TestOn('browser')
import 'package:angular2/angular2.dart';
import 'package:angular2/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  test('should be in debug mode for tests', () async {
    var fixture = await new NgTestBed<ExampleComponent>().create();
    expect(
      fixture.text,
      'true',
      reason: 'Tests should always be run in debug mode',
    );
  });
}

@Component(
  selector: 'example',
  template: '{{debugModeDetected}}',
)
class ExampleComponent {
  bool debugModeDetected;

  ExampleComponent(ChangeDetectorRef changeDetectorRef) {
    debugModeDetected = isDebugMode(changeDetectorRef);
  }
}
