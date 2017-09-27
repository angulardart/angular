@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.change_detection.component_state_test;

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

/// This is a regression test for instances where a directive on a component
/// is also a Provider. When checking DirectiveAst's on a CompileElement
/// the source is ambiguous and it is easy to call the directives' change
/// detector instead of treating it as a provider.
///
/// This test will crash if code generation is broken.
@AngularEntrypoint()
void main() {
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
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestContainer {}

@Component(
  selector: 'child-component',
  template: '<div>ChildHello</div>',
  providers: const [const Provider(SomeDirective, useExisting: ChildComponent)],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class ChildComponent extends SomeDirective {}

@Directive(selector: '[someDirective]', host: const {
  '(click)': r'handleClick($event)',
  '(keypress)': r'handleKeyPress($event)',
  'role': 'button',
  '[attr.data-xyz]': 'dataXyz',
  '[class.is-disabled]': 'disabled'
})
class SomeDirective {
  String dataXyz = 'abc';
  bool disabled = true;
  void handleClick(Event e) {}

  void handleKeyPress(KeyEvent e) {}
}
