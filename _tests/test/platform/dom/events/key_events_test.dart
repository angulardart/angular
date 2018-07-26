@TestOn('browser')

import 'dart:html';
import 'dart:js';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'key_events_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test("Should receive 'keydown' event", () async {
    var testBed = NgTestBed<KeydownListenerComponent>();
    var testFixture = await testBed.create();
    var event = KeyboardEvent('keydown');
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeydown, true);
      expect(component.receivedKeydownA, false);
      expect(component.receivedKeydownShiftA, false);
    });
  });

  test("Should receive 'keydown.a' event", () async {
    var testBed = NgTestBed<KeydownListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keydown', KeyCode.A);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeydown, true);
      expect(component.receivedKeydownA, true);
      expect(component.receivedKeydownShiftA, false);
    });
  });

  test("Should receive 'keydown.shift.a", () async {
    var testBed = NgTestBed<KeydownListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keydown', KeyCode.A, shiftKey: true);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeydown, true);
      expect(component.receivedKeydownA, false);
      expect(component.receivedKeydownShiftA, true);
    });
  });

  test("Should receive 'keypress' event", () async {
    var testBed = NgTestBed<KeypressListenerComponent>();
    var testFixture = await testBed.create();
    var event = KeyboardEvent('keypress');
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeypress, true);
    });
  });

  test("Should receive 'keyup' event", () async {
    var testBed = NgTestBed<KeyupListenerComponent>();
    var testFixture = await testBed.create();
    var event = KeyboardEvent('keyup');
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeyup, true);
      expect(component.receivedKeyupEnter, false);
      expect(component.receivedKeyupCtrlEnter, false);
    });
  });

  test("Should receive 'keyup.enter' event", () async {
    var testBed = NgTestBed<KeyupListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keyup', KeyCode.ENTER);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeyup, true);
      expect(component.receivedKeyupEnter, true);
      expect(component.receivedKeyupCtrlEnter, false);
    });
  });

  test("Should receive 'keyup.control.enter' event", () async {
    var testBed = NgTestBed<KeyupListenerComponent>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keyup', KeyCode.ENTER, ctrlKey: true);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedKeyup, true);
      expect(component.receivedKeyupEnter, false);
      expect(component.receivedKeyupCtrlEnter, true);
    });
  });

  test("Should receive keyboard event with multiple modifiers", () async {
    var testBed = NgTestBed<ModifiersListener>();
    var testFixture = await testBed.create();
    var event = createKeyboardEvent('keyup', KeyCode.NUM_ZERO,
        altKey: true, metaKey: true);
    testFixture.rootElement.dispatchEvent(event);
    await testFixture.update((component) {
      expect(component.receivedModifiers, true);
    });
  });
}

@Component(
  selector: 'keydown-listener',
  template: '<div></div>',
)
class KeydownListenerComponent {
  bool receivedKeydown = false;
  bool receivedKeydownA = false;
  bool receivedKeydownShiftA = false;

  @HostListener('keydown')
  void onKeyDown() => receivedKeydown = true;

  @HostListener('keydown.a')
  void onKeyDownA() => receivedKeydownA = true;

  @HostListener('keydown.shift.a')
  void onKeyDownShiftA() => receivedKeydownShiftA = true;
}

@Component(
  selector: 'keypress-listener',
  template: '<div></div>',
)
class KeypressListenerComponent {
  @HostListener('keypress')
  void onKeyPress() => receivedKeypress = true;

  bool receivedKeypress = false;
}

@Component(
  selector: 'keyup-listener',
  template: '<div></div>',
)
class KeyupListenerComponent {
  @HostListener('keyup')
  void onKeyUp() => receivedKeyup = true;

  @HostListener('keyup.enter')
  void onKeyUpEnter() => receivedKeyupEnter = true;

  @HostListener('keyup.control.enter')
  void onKeyUpControlEnter() => receivedKeyupCtrlEnter = true;

  bool receivedKeyup = false;
  bool receivedKeyupEnter = false;
  bool receivedKeyupCtrlEnter = false;
}

@Component(
  selector: 'modifiers-listener',
  template: '<div></div>',
)
class ModifiersListener {
  @HostListener('keyup.alt.meta.0')
  void onKeyUpAltMeta0() => receivedModifiers = true;

  bool receivedModifiers = false;
}

const CREATE_KEYBOARD_EVENT_NAME = '__dart_createKeyboardEvent';
const CREATE_KEYBOARD_EVENT_SCRIPT = '''
window['$CREATE_KEYBOARD_EVENT_NAME'] = function(
    type, keyCode, ctrlKey, altKey, shiftKey, metaKey) {
  var event = document.createEvent('KeyboardEvent');

  // Chromium hack.
  Object.defineProperty(event, 'keyCode', {
    get: function() { return keyCode; }
  });

  // Creating keyboard events programmatically isn't supported and relies on
  // these deprecated APIs.
  if (event.initKeyboardEvent) {
    event.initKeyboardEvent(type, true, true, document.defaultView, keyCode,
        keyCode, ctrlKey, altKey, shiftKey, metaKey);
  } else {
    event.initKeyEvent(type, true, true, document.defaultView, ctrlKey, altKey,
        shiftKey, metaKey, keyCode, keyCode);
  }

  return event;
}
''';

Event createKeyboardEvent(
  String type,
  int keyCode, {
  bool ctrlKey = false,
  bool altKey = false,
  bool shiftKey = false,
  bool metaKey = false,
}) {
  if (!context.hasProperty(CREATE_KEYBOARD_EVENT_NAME)) {
    var script = document.createElement('script')
      ..setAttribute('type', 'text/javascript')
      ..text = CREATE_KEYBOARD_EVENT_SCRIPT;
    document.body.append(script);
  }
  return context.callMethod(CREATE_KEYBOARD_EVENT_NAME,
      [type, keyCode, ctrlKey, altKey, shiftKey, metaKey]);
}
