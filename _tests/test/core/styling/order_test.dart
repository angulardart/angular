import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'order_test.template.dart' as ng;

/// These tests don't demonstrate a desired property of the way Angular loads
/// styles, but rather an unfortunate consequence. Angular loads a component's
/// styles the first time the component is instantiated. This has some benefits,
/// such as being able to defer a component's styles when the component itself
/// is deferred, but it also means styling can be dependent on the order in
/// which components first appear in an app.
void main() {
  late NgTestBed<TestComponent> testBed;

  setUp(() {
    testBed = NgTestBed(ng.createTestComponentFactory());
  });

  tearDown(disposeAnyRunningTest);

  group('styles of equal specificity', () {
    test('from Child win when Child is created after Parent', () async {
      // Only create Parent with nested Child.
      final testFixture = await testBed.create(
        beforeChangeDetection: (component) {
          component.isParentVisible = true;
        },
      );
      // Styles from Child are applied because they load second.
      final secondChild = testFixture.rootElement.querySelector('.test')!;
      expect(secondChild.getComputedStyle().margin, '16px');
    });

    test('from Parent win when Child is created before Parent', () async {
      // Create Child before Parent, and Parent with nested Child.
      final testFixture = await testBed.create(
        beforeChangeDetection: (component) {
          component
            ..isFirstChildVisible = true
            ..isParentVisible = true;
        },
      );
      // Styles from Parent are applied because they load second.
      final secondChild = testFixture.rootElement.querySelector('.test')!;
      expect(secondChild.getComputedStyle().margin, '8px');
    });
  });
}

@Component(
  selector: 'test',
  template: '''
    <child *ngIf="isFirstChildVisible"></child>
    <parent *ngIf="isParentVisible"></parent>
  ''',
  directives: [
    ChildComponent,
    ParentComponent,
    NgIf,
  ],
)
class TestComponent {
  var isFirstChildVisible = false;

  // We don't actually care about *not* displaying the Parent component, but it
  // must also be in an embedded view to ensure it's possible to initialize the
  // first Child component in another embedded view first.
  var isParentVisible = false;
}

/// Attempts to override margin of Child with class="test".
///
/// Because this has equal specificity, it will only apply when Parent is
/// rendered *after* Child.
@Component(
  selector: 'parent',
  template: '''
    <child class="test"></child>
  ''',
  styles: [
    '''
      .test {
        margin: 8px;
      }
    ''',
  ],
  directives: [
    ChildComponent,
  ],
)
class ParentComponent {}

/// Styles margin when class="test" is present on host element.
@Component(
  selector: 'child',
  template: '',
  styles: [
    '''
      :host(.test) {
        margin: 16px;
      }
    ''',
  ],
)
class ChildComponent {}
