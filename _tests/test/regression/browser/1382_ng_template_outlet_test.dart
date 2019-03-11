@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1382_ng_template_outlet_test.template.dart' as ng;

void main() {
  test('should not crash setting and resetting [ngTemplateOutlet]', () async {
    final testBed = NgTestBed.forComponent(ng.TestComponentNgFactory);
    final testFixture = await testBed.create();
    await testFixture.update((component) {
      // This sets the active view within `NgTemplateOutlet`.
      component.activeTemplate = component.greetingTemplate;
    });
    expect(testFixture.text.trim(), 'Hello world!');
    await testFixture.update((component) {
      // This incorrectly wouldn't invalidate the active view.
      component.activeTemplate = null;
    });
    expect(testFixture.text.trim(), isEmpty);
    await testFixture.update((component) {
      // This would attempt to remove the previously active view a second time
      // and crash.
      component.activeTemplate = component.greetingTemplate;
    });
    expect(testFixture.text.trim(), 'Hello world!');
  });
}

@Component(
  selector: 'test',
  template: '''
    <template #greeting>Hello world!</template>
    <ng-container *ngTemplateOutlet="activeTemplate"></ng-container>
  ''',
  directives: [NgTemplateOutlet],
)
class TestComponent {
  @ViewChild('greeting')
  TemplateRef greetingTemplate;
  TemplateRef activeTemplate;
}
