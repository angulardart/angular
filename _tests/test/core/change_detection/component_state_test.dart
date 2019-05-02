@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'component_state_test.template.dart' as ng;

void main() {
  tearDown(() => disposeAnyRunningTest());

  test('should update bound properties when setState is called', () async {
    var testBed = NgTestBed.forComponent(ng.TestComponentNgFactory);
    var testRoot = await testBed.create();
    Element targetElement = testRoot.rootElement.querySelector('.target');
    expect(targetElement.text, '');
    await testRoot.update((component) {
      component.componentStateChild.title = 'Matan';
    });
    expect(targetElement.text, 'Matan');
    await testRoot.update((component) {
      component.componentStateChild.updateTitle('Lurey');
    });
    // Should not have updated the template, i.e. not change detection.
    expect(targetElement.text, 'Matan');
  });
}

@Component(
  selector: 'test',
  template: '<child-with-single-binding></child-with-single-binding>',
  directives: [SingleBindingTest],
)
class TestComponent {
  @ViewChild(SingleBindingTest)
  SingleBindingTest componentStateChild;
}

@Component(
  selector: 'child-with-single-binding',
  template: r'<span class="target">{{title}}</span>',
)
class SingleBindingTest with ComponentState {
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
