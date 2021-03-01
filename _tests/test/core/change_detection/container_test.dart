import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'container_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should *not* assign any values if the initial value is null', () async {
    final fixture = await NgTestBed(ng.createBoundValueTestFactory()).create();
    await fixture.update(expectAsync1((comp) {
      expect(comp.child!.updates, 0, reason: 'No changes should have happened');
      expect(comp.child!.value, isNull);
    }));
  });

  test('should propagate null if the initial value is non-null', () async {
    final fixture = await NgTestBed(ng.createBoundValueTestFactory()).create(
      beforeChangeDetection: (comp) => comp.boundValue = 'Hello',
    );
    await fixture.update(expectAsync1((comp) {
      expect(comp.child!.updates, 1, reason: 'One CD should have happened');
      expect(comp.child!.value, 'Hello');
      comp.boundValue = null;
    }));
    await fixture.update(expectAsync1((comp) {
      expect(comp.child!.updates, 2, reason: 'Two CDs should have happened');
      expect(comp.child!.value, isNull);
    }));
  });

  test('should support interpolation', () async {
    final fixture = await NgTestBed(ng.createBoundValueTestFactory()).create(
      beforeChangeDetection: (comp) => comp.boundValue = 'Hello World',
    );
    expect(fixture.text, 'Hello World');
  });

  test('should output empty for null values in interpolation', () async {
    final fixture = await NgTestBed(ng.createBoundValueTestFactory()).create();
    expect(fixture.text, isEmpty);
  });
}

@Component(
  selector: 'child',
  template: r'{{value}}',
)
class ChildComponent {
  dynamic _value;
  var updates = 0;

  @Input()
  set value(value) {
    updates++;
    _value = value;
  }

  dynamic get value => _value;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="boundValue"></child>',
)
class BoundValueTest {
  dynamic boundValue;

  @ViewChild(ChildComponent)
  ChildComponent? child;
}
