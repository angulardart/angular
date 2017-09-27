@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.change_detection.component_state_test;

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

@AngularEntrypoint()
void main() {
  tearDown(() => disposeAnyRunningTest());

  group('ComponentState mixin', () {
    test('Should update bound properties when setState is called', () async {
      var testBed = new NgTestBed<SingleBindingTest>();
      var testRoot = await testBed.create();
      Element targetElement = testRoot.rootElement.querySelector('.target');
      expect(targetElement.text, '');
      await testRoot.update((SingleBindingTest test) {
        test.title = 'Matan';
      });
      expect(targetElement.text, 'Matan');
      await testRoot.update((SingleBindingTest test) {
        test.updateTitle('Lurey');
      });
      // Should not have updated the template, i.e. not change detection.
      expect(targetElement.text, 'Matan');
    });
  });
}

@Component(
  selector: 'child-with-single-binding',
  template: r'<span class="target">{{title}}</span>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class SingleBindingTest extends Object with ComponentState {
  String _title;
  Iterable<String> _messages;

  @Input()
  set title(String value) {
    setState(() => _title = value);
  }

  String get title => _title;

  /// Doesn't call setState on purpose to make sure title is not updated.
  void updateTitle(String value) {
    _title = value;
  }

  @Input()
  set messages(Iterable<String> messages) {
    if (_messages == messages) return;
    setState(() => _messages = messages);
  }
}
