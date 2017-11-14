@Tags(const ['codegen'])
@TestOn('browser && !js')
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';

import 'integration_dart_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

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
  template: '<template #alice>Unstamped tmp</template>'
      '<ref-reader [ref1]="alice"></ref-reader>',
  directives: const [RefReaderComponent],
)
class MyCompWithTemplateRef {}

@Component(
  selector: 'ref-reader',
  template: '<div></div>',
)
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

@Component(
  selector: 'container-with-propertyaccess',
  template: '<property-access></property-access>',
  directives: const [PropertyAccess],
)
class ContainerWithPropertyAccess {
  dynamic value;
}

@Component(
  selector: 'container-with-no-propertyaccess',
  template: '<no-property-access></no-property-access>',
  directives: const [NoPropertyAccess],
)
class ContainerWithNoPropertyAccess {
  dynamic value;
}

@Component(
  selector: 'container-with-onchange',
  template: '<on-change [prop]="\'hello\'"></on-change>',
  directives: const [OnChangeComponent],
)
class OnChangeContainer {
  dynamic value;
}

class PropModel implements Map {
  final String foo = 'foo-prop';

  String operator [](_) => 'foo-map';

  dynamic noSuchMethod(_) {
    throw 'property not found';
  }

  get doesNotExist;
}

@Component(
  selector: 'property-access',
  template: '''prop:{{model.foo}};map:{{model['foo']}}''',
)
class PropertyAccess {
  final model = new PropModel();
}

@Component(
  selector: 'no-property-access',
  template: '''{{model.doesNotExist}}''',
)
class NoPropertyAccess {
  final model = new PropModel();
}

@Component(
  selector: 'on-change',
  template: '',
)
class OnChangeComponent implements OnChanges {
  Map changes;
  @Input()
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
