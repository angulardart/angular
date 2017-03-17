@Tags(const ['codegen'])
@TestOn('browser && !js')
library angular2.test.core.linker.host_events_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

// Not common practice, just to avoid a circular pub transformer dependency.
// ignore: uri_has_not_been_generated
import 'host_events_test.template.dart' as ng_codegen;

void main() {
  ng_codegen.initReflector();

  group('Events', () {
    tearDown(() => disposeAnyRunningTest());
    test('defined inside component itself should add listeners', () async {
      var testBed = new NgTestBed<ComponentWithEventTest>();
      var testFixture = await testBed.create();
      Element element =
          testFixture.rootElement.querySelector('component-with-event > input');
      expect(element, isNotNull);
      expect(element.attributes["has-focus"], 'false');
      element.focus();
      await testFixture.update();
      expect(element.attributes["has-focus"], 'true');
    });
    test('defined on host should add listeners', () async {
      var testBed = new NgTestBed<ComponentWithHostEvent>();
      var testFixture = await testBed.create();
      Element divElement = testFixture.rootElement
          .querySelector('component-with-hostevent > div');
      expect(divElement, isNotNull);
      Element hostElement = divElement.parent;
      hostElement.tabIndex = 1;
      hostElement.focus();
      await testFixture.update();
      expect(divElement.attributes['has-focus'], 'true');
    });
  });
}

@Component(
    selector: 'component-with-event-test',
    template: '<component-with-event></component-with-event>',
    directives: const [ComponentWithEvent])
class ComponentWithEventTest {}

@Component(
    selector: 'component-with-event',
    template: '<input id="my_element" (focus)="onFocus()" (blur)="onBlur()" '
        '[attr.has-focus]="hasFocus">')
class ComponentWithEvent {
  bool hasFocus = false;
  void onFocus() {
    hasFocus = true;
  }

  void onBlur() {
    hasFocus = false;
  }
}

@Component(
    selector: 'component-with-hostevent',
    host: const {
      '(focus)': 'onFocus()',
      '(blur)': 'onBlur()',
      '(click)': 'toggled = !toggled'
    },
    template: '<div [attr.has-focus]="hasFocus"></div>')
class ComponentWithHostEvent {
  bool hasFocus = false;
  bool toggled = false;

  void onFocus() {
    hasFocus = true;
  }

  void onBlur() {
    hasFocus = false;
  }
}
