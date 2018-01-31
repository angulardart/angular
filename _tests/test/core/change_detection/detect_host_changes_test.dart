@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.change_detection.component_state_test;

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'detect_host_changes_test.template.dart' as ng_generated;

/// This is a regression test for instances where a directive on a component
/// is also a Provider. When checking DirectiveAst's on a CompileElement
/// the source is ambiguous and it is easy to call the directives' change
/// detector instead of treating it as a provider.
///
/// This test will crash if code generation is broken.
void main() {
  ng_generated.initReflector();

  tearDown(() => disposeAnyRunningTest());

  test('Should update bound properties when setState is called', () async {
    var testBed = new NgTestBed<TestContainer>();
    var testRoot = await testBed.create();
    Element targetElement = testRoot.rootElement.querySelector('.mytarget');
    expect(targetElement.firstChild.text, 'ChildHello');
    expect(targetElement.attributes['data-xyz'], 'abc');
  });
}

@Component(
  selector: 'test-container',
  template: '<child-component class="mytarget" someDirective>'
      '</child-component>',
  directives: const [ChildComponent, SomeDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestContainer {}

@Component(
  selector: 'child-component',
  template: '<div>ChildHello</div>',
  providers: const [const Provider(SomeDirective, useExisting: ChildComponent)],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ChildComponent extends SomeDirective {}

@Directive(
  selector: '[someDirective]',
  host: const {
    '(click)': r'handleClick($event)',
    '(keypress)': r'handleKeyPress($event)',
    'role': 'button',
    '[attr.data-xyz]': 'dataXyz',
    '[class.is-disabled]': 'disabled'
  },
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SomeDirective {
  String dataXyz = 'abc';
  bool disabled = true;
  void handleClick(Event e) {}

  void handleKeyPress(KeyEvent e) {}
}
