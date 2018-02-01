@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'component_state_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

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

    test('Should update bound attribute with change detection', () async {
      var testBed = new NgTestBed<DirectiveContainerTest>();
      var testRoot = await testBed.create();
      Element targetElement = testRoot.rootElement.querySelector('.target1');
      expect(targetElement.attributes['data-msg'], 'Hello xyz');
      targetElement = testRoot.rootElement.querySelector('.target2');
      expect(targetElement.attributes['data-msg'], 'Hello abc');
    });
  });
}

@Component(
  selector: 'child-with-single-binding',
  template: r'<span class="target">{{title}}</span>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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

@Directive(
    host: const {'[attr.data-msg]': 'msg'},
    selector: '[fastDirective]',
    visibility: Visibility.local)
class FastDirective extends ComponentState {
  Element element;
  String msg;
  String _prevValue;

  FastDirective(this.element);

  @Input()
  set name(String value) {
    if (_prevValue == value) return;
    _prevValue = value;
    setState(() => msg = 'Hello $value');
  }
}

@Component(
    selector: 'directive-container',
    template: r'<div class="target1" fastDirective [name]="finalName"></div>'
        '<div class="target2" fastDirective [name]="nonFinal"></div>',
    directives: const [FastDirective],
    visibility: Visibility.local)
class DirectiveContainerTest {
  final String finalName = "xyz";
  String nonFinal = "abc";
}
