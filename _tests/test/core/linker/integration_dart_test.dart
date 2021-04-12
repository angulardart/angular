import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'integration_dart_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('Property access', () {
    test('should not fallback on map access if property missing', () async {
      var testBed = NgTestBed(ng.createContainerWithNoPropertyAccessFactory());
      expect(testBed.create(), throwsStateError);
    });
  });

  group('Reference in Template element', () {
    test('should assign the TemplateRef to a user-defined variable', () async {
      var testBed = NgTestBed(ng.createMyCompWithTemplateRefFactory());
      var testFixture = await testBed.create();
      var refReader = testFixture.assertOnlyInstance.refReaderComponent;
      expect(refReader!.ref1, TypeMatcher<TemplateRef>());
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
  RefReaderComponent? refReaderComponent;
}

@Component(
  selector: 'ref-reader',
  template: '<div></div>',
)
class RefReaderComponent {
  @Input()
  TemplateRef? ref1;
}

@Component(
  selector: 'container-with-no-propertyaccess',
  template: '<no-property-access></no-property-access>',
  directives: [NoPropertyAccess],
)
class ContainerWithNoPropertyAccess {}

@Component(
  selector: 'no-property-access',
  template: '''{{model.doesNotExist}}''',
)
class NoPropertyAccess {
  final model = PropModel();
}

class PropModel implements Map<void, void> {
  final String foo = 'foo-prop';

  @override
  String operator [](_) => 'foo-map';

  @override
  dynamic noSuchMethod(_) {
    throw StateError('property not found');
  }

  dynamic get doesNotExist;
}
