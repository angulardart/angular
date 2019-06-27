@TestOn('browser')
import 'dart:async';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'binding_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support literals', () async {
    await _GetValue<TestLiterals>().runTest();
  });

  test('should strip quotes from literals', () async {
    await _GetValue<TestStripQuotes>().runTest();
  });

  test('should support newlines in literals', () async {
    await _GetValue<TestNewLines>().runTest();
  });

  test('should support + operations', () async {
    await _GetValue<TestAddOperation>().runTest();
  });

  test('should support - operations', () async {
    await _GetValue<TestMinusOperation>().runTest();
  });

  test('should support * operations', () async {
    await _GetValue<TestMultiplyOperation>().runTest();
  });

  test('should support / operations', () async {
    await _GetValue<TestMultiplyOperation>().runTest();
  });

  test('should support % operations', () async {
    await _GetValue<TestModulusOperation>().runTest();
  });

  test('should support == operations', () async {
    await _GetValue<TestEqualityOperation>().runTest();
  });

  test('should support != operations', () async {
    await _GetValue<TestNotEqualsOperation>().runTest();
  });

  test('should support === operations', () async {
    await _GetValue<TestIdentityOperation>().runTest();
  });

  test('should support !== operations', () async {
    await _GetValue<TestNotIdenticalOperation>().runTest();
  });

  test('should support > operations', () async {
    await _GetValue<TestGreaterThanOperation>().runTest();
  });

  test('should support < operations', () async {
    await _GetValue<TestLessThanOperation>().runTest();
  });

  test('should support >= operations', () async {
    await _GetValue<TestGreaterThanOrEqualsOperation>().runTest();
  });

  test('should support <= operations', () async {
    await _GetValue<TestLessThanOrEqualsOperation>().runTest();
  });

  test('should support && operations', () async {
    await _GetValue<TestAndOperation>().runTest();
  });

  test('should support || operations', () async {
    await _GetValue<TestOrOperation>().runTest();
  });

  test('should support ternary operations', () async {
    await _GetValue<TestTernaryOperation>().runTest();
  });

  test('should support ! operations', () async {
    await _GetValue<TestNegateOperation>().runTest();
  });

  test('should support !! operations', () async {
    await _GetValue<TestDoubleNegationOperation>().runTest();
  });

  test('should support keyed access to a map', () async {
    await _GetValue<TestMapAccess>().runTest();
  });

  test('should support keyed access to a list', () async {
    await _GetValue<TestListAccess>().runTest();
  });

  test('should support property access', () async {
    await _GetValue<TestPropertyAccess>().runTest();
  });

  test('should support chained property access', () async {
    await _GetValue<TestChainedPropertyAccess>().runTest();
  });

  test('should support a function call', () async {
    await _GetValue<TestFunctionCall>().runTest();
  });

  test('should support assigning explicitly to null', () async {
    await _GetValue<TestAssignNull>().runTest();
  });

  test('should support assigning explicitly to null', () async {
    await _GetValue<TestElvisOperation>().runTest();
  });

  test('should support assigning explicitly to null', () async {
    await _GetValue<TestNullAwareOperation>().runTest();
  });
}

/// A helper for asserting against a new component that implements [ValueTest].
class _GetValue<T extends ValueTest> {
  const _GetValue();

  Future<Null> runTest() async {
    final fixture = await NgTestBed<T>().create();
    await fixture.update(expectAsync1((ValueTest comp) {
      expect(comp.child.value, comp.expected);
    }));
  }
}

@Component(
  selector: 'child',
  template: r'{{value}}',
)
class ChildComponent {
  @Input()
  var value;
}

abstract class ValueTest {
  ChildComponent get child;

  get expected;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'<child [value]="10"></child>',
)
class TestLiterals implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 10;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="'string'"></child>''',
)
class TestStripQuotes implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 'string';
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '''<child [value]="value"></child>''',
)
class TestNewLines implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 'a\n\nb';

  // TODO(b/136199519): Move the value back inline in the template.
  var value = 'a\n\nb';
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="10 + 2"></child>',
)
class TestAddOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 12;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="10 - 2"></child>',
)
class TestMinusOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 8;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="10 * 2"></child>',
)
class TestMultiplyOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 20;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="10 / 2"></child>',
)
class TestDivisionOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 5;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="11 % 2"></child>',
)
class TestModulusOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 1;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="1 == 1"></child>',
)
class TestEqualityOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="1 != 1"></child>',
)
class TestNotEqualsOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => isFalse;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="1 === 1"></child>',
)
class TestIdentityOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="1 !== 1"></child>',
)
class TestNotIdenticalOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => isFalse;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="1 < 2"></child>',
)
class TestLessThanOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="2 > 1"></child>',
)
class TestGreaterThanOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="1 <= 2"></child>',
)
class TestLessThanOrEqualsOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="2 >= 1"></child>',
)
class TestGreaterThanOrEqualsOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="true && false"></child>',
)
class TestAndOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => isFalse;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="val1 || val2"></child>',
)
class TestOrOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  // Can't inline; we'd get a dead code warning in .template.dart.
  bool get val1 => true;
  bool get val2 => false;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="!true"></child>',
)
class TestNegateOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => isFalse;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: '<child [value]="!!true"></child>',
)
class TestDoubleNegationOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="1 > 2 ? 'yes' : 'no'"></child>''',
)
class TestTernaryOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 'no';
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="map['foo']"></child>''',
)
class TestMapAccess implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get map => const {'foo': 'bar'};

  @override
  get expected => 'bar';
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="list[1]"></child>''',
)
class TestListAccess implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get list => const ['foo', 'bar'];

  @override
  get expected => 'bar';
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="list.length"></child>''',
)
class TestPropertyAccess implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get list => const ['foo', 'bar'];

  @override
  get expected => 2;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="list.length.isEven"></child>''',
)
class TestChainedPropertyAccess implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get list => const ['foo', 'bar'];

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="list.toList().length.isEven"></child>''',
)
class TestFunctionCall implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get list => const ['foo', 'bar'];

  @override
  get expected => true;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="null"></child>''',
)
class TestAssignNull implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => isNull;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="map?.keys"></child>''',
)
class TestElvisOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get map => null;

  @override
  get expected => isNull;
}

@Component(
  selector: 'test',
  directives: [ChildComponent],
  template: r'''<child [value]="map?.keys ?? 'Hello'"></child>''',
)
class TestNullAwareOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get map => null;

  @override
  get expected => 'Hello';
}
