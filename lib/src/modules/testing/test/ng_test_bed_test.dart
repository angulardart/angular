import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/modules/testing/lib/src/error_matchers.dart';
import 'package:angular2/src/modules/testing/lib/src/errors.dart';
import 'package:angular2/src/modules/testing/lib/src/ng_test_bed.dart';
import 'package:test/test.dart';

void main() {
  group('$NgTestBed', () {
    test('should fail if a generic type is not specified', () async {
      expect(
        () => new NgTestBed(),
        throwsA(const isInstanceOf<GenericTypeRequiredError>()),
      );
    });

    group('[create]', () {
      Element docRoot;
      Element testRoot;

      setUp(() {
        docRoot = new Element.tag('doc-root');
        testRoot = new Element.tag('ng-test-bed-test');
        docRoot.append(testRoot);
      });

      tearDown(() => disposeAnyRunningTest());

      test('should start an Angular instance', () async {
        // Create a new test, and load within the test element.
        final bed = new NgTestBed<HelloPlaceComponent>(
          host: testRoot,
          watchAngularLifecycle: false,
        );

        // Create an Angular instance, and run an assertion.
        final fixture = await bed.create();
        expect(docRoot.text, contains('Hello World'));

        // Assert that change detection is not occurring.
        await fixture.update((component) {
          component.place = 'Universe';
        });
        expect(docRoot.text, contains('Hello World'));

        // Destroy the instance, and run an assertion.
        await fixture.dispose();
        expect(docRoot.text, isEmpty);
      });

      test('should support waiting for the Angular lifecycle', () async {
        final bed = new NgTestBed<HelloPlaceComponent>(host: testRoot);
        final fixture = await bed.create();
        await fixture.update((component) {
          component.place = 'Universe';
        });
        expect(docRoot.text, contains('Hello Universe'));
      });

      /* TODO(matanl): Support catching synchronously thrown exceptions.
      test('should support catching sync exceptions in update()', () async {
        final bed = new NgTestBed<UpdateFailsComponent>(host: testRoot);
        final fixture = await bed.create();
        await fixture.update((component) {
          expect(component.causeException(), throwsIntentional);
        });
      });
      */

      test('should support catching exceptions from a constructor', () async {
        final bed = new NgTestBed<ConstructorFailsComponent>(host: testRoot);
        expect(bed.create(), throwsIntentional);
      });

      test('should support catching exceptions from ngOnInit', () async {
        final bed = new NgTestBed<OnInitFailsComponent>(host: testRoot);
        expect(bed.create(), throwsIntentional);
      });

      /* TODO(matanl): Support catching asynchronously thrown exceptions.
      test('should support catching exceptions from changes', () async {
        final bed = new NgTestBed<ChangesFailsComponent>(host: testRoot);
        final fixture = await bed.create();

        // Should not throw.
        await fixture.update((c) => c.value = false);
        expect(testRoot.text, contains('VALUE: false'));

        // Should throw.
        expect(fixture.update((c) => c.value = true), throwsIntentional);
      });
      */
    });
  });
}

final Matcher isIntentional = const isInstanceOf<IntentionalException>();
final Matcher throwsIntentional = throwsInAngular(isIntentional);

class IntentionalException implements Exception {}

@Component(
  selector: 'ng-test-bed-test',
  template: 'Hello {{place}}',
)
class HelloPlaceComponent {
  String place = 'World';
}

@Component(
  selector: 'update-fails',
  template: '',
)
class UpdateFailsComponent {
  void causeException() {
    throw new IntentionalException();
  }
}

@Component(
  selector: 'constructor-fails',
  template: '',
)
class ConstructorFailsComponent {
  ConstructorFailsComponent() {
    throw new IntentionalException();
  }
}

@Component(
  selector: 'on-init-fails',
  template: '',
)
class OnInitFailsComponent implements OnInit {
  @override
  void ngOnInit() {
    throw new IntentionalException();
  }
}

@Component(
  selector: 'changes-fails',
  template: '<throws-when-value-true [value]="value"></throws-when-value-true>',
  directives: const [
    ThrowsWhenValueTrueComponent,
  ],
)
class ChangesFailsComponent {
  bool value;
}

@Component(
  selector: 'throws-when-value-true',
  template: 'VALUE: {{value}}',
)
class ThrowsWhenValueTrueComponent {
  bool _value;

  bool get value => _value;

  @Input()
  set value(value) {
    if (value == true) {
      throw new IntentionalException();
    }
    _value = value;
  }
}
