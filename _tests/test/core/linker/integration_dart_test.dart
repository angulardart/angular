@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'integration_dart_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('Property access', () {
    test('should not fallback on map access if property missing', () async {
      var testBed = NgTestBed.forComponent(
          ng.createContainerWithNoPropertyAccessFactory());
      await testBed.create().catchError((e, stack) {
        expect(e.toString(), contains('property not found'));
      });
    });
  });

  group('$AfterChanges', () {
    test('should be notified of changes', () async {
      var testBed =
          NgTestBed.forComponent(ng.createAfterChangeContainerFactory());
      var testFixture = await testBed.create();
      var cmp = testFixture.assertOnlyInstance.child;
      expect(cmp.prop, 'hello');
      expect(cmp.changed, true);
    });
  });

  group('Reference in Template element', () {
    test('should assign the TemplateRef to a user-defined variable', () async {
      var testBed =
          NgTestBed.forComponent(ng.createMyCompWithTemplateRefFactory());
      var testFixture = await testBed.create();
      var refReader = testFixture.assertOnlyInstance.refReaderComponent;
      expect(refReader.ref1, TypeMatcher<TemplateRef>());
    });
  });
}

@Component(
  selector: 'my-comp-with-tref',
  template: '<template #alice>Unstamped tmp</template>'
      '<ref-reader [ref1]="alice"></ref-reader>',
  directives: [RefReaderComponent],
)
class MyCompWithTemplateRef {
  @ViewChild(RefReaderComponent)
  RefReaderComponent refReaderComponent;
}

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
  @override
  var stackTrace;
}

class NonError {
  var message;
}

@Component(
  selector: 'container-with-no-propertyaccess',
  template: '<no-property-access></no-property-access>',
  directives: [NoPropertyAccess],
)
class ContainerWithNoPropertyAccess {}

@Component(
  selector: 'container-with-afterchange',
  template: '<after-change [prop]="\'hello\'"></after-change>',
  directives: [AfterChangeComponent],
)
class AfterChangeContainer {
  @ViewChild(AfterChangeComponent)
  AfterChangeComponent child;
}

class PropModel implements Map {
  final String foo = 'foo-prop';

  @override
  String operator [](_) => 'foo-map';

  @override
  dynamic noSuchMethod(_) {
    throw StateError('property not found');
  }

  dynamic get doesNotExist;
}

@Component(
  selector: 'property-access',
  template: '''prop:{{model.foo}};map:{{model['foo']}}''',
)
class PropertyAccess {
  final model = PropModel();
}

@Component(
  selector: 'no-property-access',
  template: '''{{model.doesNotExist}}''',
)
class NoPropertyAccess {
  final model = PropModel();
}

@Component(
  selector: 'after-change',
  template: '',
)
class AfterChangeComponent implements AfterChanges {
  bool changed = false;
  @Input()
  String prop;

  @override
  void ngAfterChanges() {
    changed = true;
  }
}

@Directive(
  selector: 'directive-logging-checks',
)
class DirectiveLoggingChecks implements DoCheck {
  Logger log;

  DirectiveLoggingChecks(this.log);

  @override
  void ngDoCheck() => log.info('check');
}
