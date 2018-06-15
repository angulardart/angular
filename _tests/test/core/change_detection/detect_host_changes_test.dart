@TestOn('browser')

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
    var testBed = NgTestBed<TestContainer>();
    var testRoot = await testBed.create();
    Element targetElement = testRoot.rootElement.querySelector('.mytarget');
    expect(targetElement.firstChild.text, 'ChildHello');
    expect(targetElement.attributes['data-xyz'], 'abc');
  });
}

@Component(
  selector: 'test-container',
  template: r'''
    <child-component class="mytarget" someDirective>
    </child-component>
  ''',
  directives: [ChildComponent, SomeDirective],
)
class TestContainer {}

@Component(
  selector: 'child-component',
  template: '<div>ChildHello</div>',
  providers: [Provider(SomeDirective, useExisting: ChildComponent)],
)
class ChildComponent extends SomeDirective {}

@Directive(
  selector: '[someDirective]',
)
class SomeDirective {
  @HostBinding('attr.role')
  static const hostRole = 'button';

  @HostBinding('attr.data-xyz')
  String dataXyz = 'abc';

  @HostBinding('class.is-disabled')
  bool disabled = true;

  @HostListener('click')
  void handleClick(Event e) {}

  @HostListener('keypress')
  void handleKeyPress(KeyEvent e) {}
}
