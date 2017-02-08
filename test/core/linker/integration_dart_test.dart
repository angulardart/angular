@TestOn('browser && !js')
library angular2.test.di.integration_dart_test;

import 'dart:html';
import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular2/src/testing/matchers.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

void main() {
  group('Error handling', () {
    tearDown(() => disposeAnyRunningTest());
    test('should preserve Error stack traces thrown from components', () async {
      var testBed = new NgTestBed<ContainerWithThrowingComponent>();
      await testBed.create().catchError((e) {
        expect(e.toString(), contains("MockException"));
        expect(e.toString(), contains("functionThatThrows"));
      });
    });

    test('should preserve non-Error stack traces thrown from components',
        () async {
      var testBed = new NgTestBed<ContainerWithThrowingComponent2>();
      await testBed.create().catchError((e, stack) {
        expect(e.toString(), contains("NonError"));
        expect(e.toString(), contains("functionThatThrows"));
      });
    });
  });

  group('Property access', () {
    test('should distinguish between map and property access', () async {
      var testBed = new NgTestBed<ContainerWithPropertyAccess>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      DebugElement debugElement = getDebugNode(element);
      expect(debugElement.children.map((DebugElement e) => e.nativeElement),
          hasTextContent('prop:foo-prop;map:foo-map'));
    });

    test('should not fallback on map access if property missing', () async {
      var testBed = new NgTestBed<ContainerWithNoPropertyAccess>();
      await testBed.create().catchError((e, stack) {
        expect(e.toString(), contains("property not found"));
      });
    });
  });

  group('OnChange', () {
    test('should be notified of changes', () async {
      var testBed = new NgTestBed<OnChangeContainer>();
      var testFixture = await testBed.create();
      DebugElement debugElement = getDebugNode(testFixture.rootElement);
      var cmp = debugElement.children[0].inject(OnChangeComponent);
      expect(cmp.prop, 'hello');
      expect(cmp.changes.containsKey('prop'), true);
    });
  });

  group('Reference in Template element', () {
    test('should assign the TemplateRef to a user-defined variable', () async {
      var testBed = new NgTestBed<MyCompWithTemplateRef>();
      var testFixture = await testBed.create();
      DebugElement debugElement = getDebugNode(testFixture.rootElement);
      var refReader = debugElement.childNodes[1].componentInstance;
      expect(refReader.ref1, new isInstanceOf<TemplateRef>());
    });
  });
}

@Component(
    selector: 'my-comp-with-tref',
    template: '<template ref-alice>Unstamped tmp</template>'
        '<ref-reader [ref1]="alice"></ref-reader>',
    directives: const [RefReaderComponent])
class MyCompWithTemplateRef {}

@Component(selector: 'ref-reader', template: '<div></div>')
class RefReaderComponent {
  @Input()
  TemplateRef ref1;
}

class MockException implements Error {
  var message;
  var stackTrace;
}

class NonError {
  var message;
}

void functionThatThrows() {
  try {
    throw new MockException();
  } catch (e, stack) {
    // If we lose the stack trace the message will no longer match
    // the first line in the stack
    e.message = stack.toString().split('\n')[0];
    e.stackTrace = stack;
    rethrow;
  }
}

void functionThatThrowsNonError() {
  try {
    throw new NonError();
  } catch (e, stack) {
    // If we lose the stack trace the message will no longer match
    // the first line in the stack
    e.message = stack.toString().split('\n')[0];
    rethrow;
  }
}

@Component(selector: 'throwing-component')
@View(template: '')
class ThrowingComponent {
  ThrowingComponent() {
    functionThatThrows();
  }
}

@Component(selector: 'throwing-component2')
@View(template: '')
class ThrowingComponent2 {
  ThrowingComponent2() {
    functionThatThrowsNonError();
  }
}

@Component(
    selector: 'container-with-throwing',
    template: '<throwing-component></throwing-component>',
    directives: const [ThrowingComponent])
class ContainerWithThrowingComponent {
  dynamic value;
}

@Component(
    selector: 'container-with-throwing2',
    template: '<throwing-component></throwing-component>',
    directives: const [ThrowingComponent2])
class ContainerWithThrowingComponent2 {
  dynamic value;
}

@Component(
    selector: 'container-with-propertyaccess',
    template: '<property-access></property-access>',
    directives: const [PropertyAccess])
class ContainerWithPropertyAccess {
  dynamic value;
}

@Component(
    selector: 'container-with-no-propertyaccess',
    template: '<no-property-access></no-property-access>',
    directives: const [NoPropertyAccess])
class ContainerWithNoPropertyAccess {
  dynamic value;
}

@Component(
    selector: 'container-with-onchange',
    template: '<on-change [prop]="\'hello\'"></on-change>',
    directives: const [OnChangeComponent])
class OnChangeContainer {
  dynamic value;
}

@proxy
class PropModel implements Map {
  final String foo = 'foo-prop';

  String operator [](_) => 'foo-map';

  dynamic noSuchMethod(_) {
    throw 'property not found';
  }
}

@Component(selector: 'property-access')
@View(template: '''prop:{{model.foo}};map:{{model['foo']}}''')
class PropertyAccess {
  final model = new PropModel();
}

@Component(selector: 'no-property-access')
@View(template: '''{{model.doesNotExist}}''')
class NoPropertyAccess {
  final model = new PropModel();
}

@Component(selector: 'on-change', inputs: const ['prop'])
@View(template: '')
class OnChangeComponent implements OnChanges {
  Map changes;
  String prop;

  @override
  void ngOnChanges(Map changes) {
    this.changes = changes;
  }
}

@Directive(selector: 'directive-logging-checks')
class DirectiveLoggingChecks implements DoCheck {
  Logger log;

  DirectiveLoggingChecks(this.log);

  @override
  ngDoCheck() => log.info("check");
}
