@Tags(const ['codegen'])
@TestOn('browser && !js')
import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  group('Events defined', () {
    Element activeElement;
    NgTestFixture testFixture;

    tearDown(disposeAnyRunningTest);

    /// Runs a comment test based on a populated [activeElement].
    Future<Null> _commonFocusTest({Element checkElement}) async {
      checkElement ??= activeElement;
      expect(activeElement, isNotNull, reason: 'Did not find an element');
      expect(checkElement.attributes['has-focus'], 'false');
      await testFixture.update((_) {
        activeElement.focus();
      });
      expect(
        checkElement.attributes['has-focus'],
        'true',
        reason: 'Expected an element to have reported focus',
      );
    }

    test('inside a component\'s template should add listeners', () async {
      const selector = 'component-with-event > input';
      testFixture = await new NgTestBed<ComponentWithEventTest>().create();
      activeElement = testFixture.rootElement.querySelector(selector);
      await _commonFocusTest();
    });

    test('inside a component\'s host property should add listeners', () async {
      const selector = 'component-with-hostevent > div';
      testFixture = await new NgTestBed<ComponentWithHostEvent>().create();
      Element divElement = testFixture.rootElement.querySelector(selector);
      activeElement = divElement.parent;
      activeElement.tabIndex = 1;
      await _commonFocusTest(checkElement: divElement);
    });

    test('inside a component\'s annotations should add listeners', () async {
      const selector = 'component-with-annotation > div';
      testFixture = await new NgTestBed<ComponentWithHostAnnotation>().create();
      Element divElement = testFixture.rootElement.querySelector(selector);
      expect(divElement, isNotNull);
      activeElement = divElement.parent;
      activeElement.tabIndex = 1;
      await _commonFocusTest(checkElement: divElement);
    });

    test('inside a component\'s annotation supports an event', () async {
      const selector = 'component-with-annotation2 > div';
      testFixture = await new NgTestBed<ComponentWithHost$Event>().create();
      Element divElement = testFixture.rootElement.querySelector(selector);
      expect(divElement, isNotNull);
      expect(divElement.attributes['was-clicked'], 'false');
      await testFixture.update((_) {
        testFixture.rootElement.click();
      });
      expect(divElement.attributes['was-clicked'], 'true');
    });
  });
}

@Component(
  selector: 'component-with-event-test',
  template: '<component-with-event></component-with-event>',
  directives: const [ComponentWithEvent],
)
class ComponentWithEventTest {}

/// Tests that `(event)="..."` works.
@Component(
  selector: 'component-with-event',
  template: r'''
    <input
      id="my_element"
      (focus)="onFocus()"
      (blur)="onBlur()"
      [attr.has-focus]="hasFocus">
  ''',
)
class ComponentWithEvent {
  bool hasFocus = false;

  void onFocus() {
    hasFocus = true;
  }

  void onBlur() {
    hasFocus = false;
  }
}

/// Tests that `@Component(host: ...)` works.
@Component(
  selector: 'component-with-hostevent',
  host: const {
    '(focus)': 'onFocus()',
    '(blur)': 'onBlur()',
  },
  template: '<div [attr.has-focus]="hasFocus"></div>',
)
class ComponentWithHostEvent {
  bool hasFocus = false;

  void onFocus() {
    hasFocus = true;
  }

  void onBlur() {
    hasFocus = false;
  }
}

/// Tests that `@HostListener()` works.
@Component(
  selector: 'component-with-annotation',
  template: '<div [attr.has-focus]="hasFocus"></div>',
)
class ComponentWithHostAnnotation {
  bool hasFocus = false;

  @HostListener('focus')
  void onFocus() {
    hasFocus = true;
  }

  @HostListener('blur')
  void onBlur() {
    hasFocus = false;
  }
}

@Component(
  selector: 'component-with-annotation2',
  template: '<div [attr.was-clicked]="wasClicked"></div>',
)
class ComponentWithHost$Event {
  bool wasClicked = false;

  @HostListener('click', const [r'$event'])
  void onClick(MouseEvent event) {
    if (event == null) {
      throw 'EXPECTED a $MouseEvent, but got null';
    }
    wasClicked = true;
  }
}
