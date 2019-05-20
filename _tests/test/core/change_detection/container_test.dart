@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'container_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should *not* assign any values if the initial value is null', () async {
    final fixture = await NgTestBed<BoundValueTest>().create();
    await fixture.update(expectAsync1((comp) {
      expect(comp.child.updates, 0, reason: 'No changes should have happened');
      expect(comp.child.value, isNull);
    }));
  });

  test('should propagate null if the initial value is non-null', () async {
    final fixture = await NgTestBed<BoundValueTest>().create(
      beforeChangeDetection: (comp) => comp.boundValue = 'Hello',
    );
    await fixture.update(expectAsync1((comp) {
      expect(comp.child.updates, 1, reason: 'One CD should have happened');
      expect(comp.child.value, 'Hello');
      comp.boundValue = null;
    }));
    await fixture.update(expectAsync1((comp) {
      expect(comp.child.updates, 2, reason: 'Two CDs should have happened');
      expect(comp.child.value, isNull);
    }));
  });

  test('should not recreate literal lists unless content changes', () async {
    List boundList;
    final fixture = await NgTestBed<BoundListTest>().create(
      beforeChangeDetection: (comp) {
        comp.value = 'bar';
      },
    );
    await fixture.update(expectAsync1((comp) {
      boundList = comp.child.value;
      expect(boundList, ['bar']);
    }));
    await fixture.update(expectAsync1((comp) {
      expect(boundList, same(comp.child.value), reason: 'Should be identical');
      comp.value = 'foo';
    }));
    await fixture.update(expectAsync1((comp) {
      expect(comp.child.value, ['foo']);
    }));
  });

  test('should support interpolation', () async {
    final fixture = await NgTestBed<BoundValueTest>().create(
      beforeChangeDetection: (comp) => comp.boundValue = 'Hello World',
    );
    expect(fixture.text, 'Hello World');
  });

  test('should output empty for null values in interpolation', () async {
    final fixture = await NgTestBed<BoundValueTest>().create();
    expect(fixture.text, isEmpty);
  });
}

@Component(
  selector: 'child',
  template: r'{{value}}',
)
class ChildComponent {
  var _value;
  var updates = 0;

  @Input()
  set value(value) {
    updates++;
    _value = value;
  }

  get value => _value;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="boundValue"></child>',
)
class BoundValueTest {
  var boundValue;

  @ViewChild(ChildComponent)
  ChildComponent child;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="[value]"></child>''',
)
class BoundListTest {
  var value;

  @ViewChild(ChildComponent)
  ChildComponent child;
}
