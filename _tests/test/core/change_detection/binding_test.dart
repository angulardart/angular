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
    await new _GetValue<TestLiterals>().runTest();
  });

  test('should strip quotes from literals', () async {
    await new _GetValue<TestStripQuotes>().runTest();
  });

  test('should support newlines in literals', () async {
    await new _GetValue<TestNewLines>().runTest();
  });

  test('should support + operations', () async {
    await new _GetValue<TestAddOperation>().runTest();
  });

  test('should support - operations', () async {
    await new _GetValue<TestMinusOperation>().runTest();
  });

  test('should support * operations', () async {
    await new _GetValue<TestMultiplyOperation>().runTest();
  });

  test('should support / operations', () async {
    await new _GetValue<TestMultiplyOperation>().runTest();
  });

  test('should support % operations', () async {
    await new _GetValue<TestModulusOperation>().runTest();
  });

  test('should support == operations', () async {
    await new _GetValue<TestEqualityOperation>().runTest();
  });

  test('should support != operations', () async {
    await new _GetValue<TestNotEqualsOperation>().runTest();
  });

  test('should support === operations', () async {
    await new _GetValue<TestIdentityOperation>().runTest();
  });

  test('should support !== operations', () async {
    await new _GetValue<TestNotIdenticalOperation>().runTest();
  });

  test('should support > operations', () async {
    await new _GetValue<TestGreaterThanOperation>().runTest();
  });

  test('should support < operations', () async {
    await new _GetValue<TestLessThanOperation>().runTest();
  });

  test('should support >= operations', () async {
    await new _GetValue<TestGreaterThanOrEqualsOperation>().runTest();
  });

  test('should support <= operations', () async {
    await new _GetValue<TestLessThanOrEqualsOperation>().runTest();
  });

  test('should support && operations', () async {
    await new _GetValue<TestAndOperation>().runTest();
  });

  test('should support || operations', () async {
    await new _GetValue<TestOrOperation>().runTest();
  });

  test('should support ternary operations', () async {
    await new _GetValue<TestTernaryOperation>().runTest();
  });

  test('should support ! operations', () async {
    await new _GetValue<TestNegateOperation>().runTest();
  });

  test('should support !! operations', () async {
    await new _GetValue<TestDoubleNegationOperation>().runTest();
  });

  test('should support keyed access to a map', () async {
    await new _GetValue<TestMapAccess>().runTest();
  });

  test('should support keyed access to a list', () async {
    await new _GetValue<TestListAccess>().runTest();
  });

  test('should support property access', () async {
    await new _GetValue<TestPropertyAccess>().runTest();
  });

  test('should support chained property access', () async {
    await new _GetValue<TestChainedPropertyAccess>().runTest();
  });

  test('should support a function call', () async {
    await new _GetValue<TestFunctionCall>().runTest();
  });

  test('should support assigning explicitly to null', () async {
    await new _GetValue<TestAssignNull>().runTest();
  });

  test('should support assigning explicitly to null', () async {
    await new _GetValue<TestElvisOperation>().runTest();
  });

  test('should support assigning explicitly to null', () async {
    await new _GetValue<TestNullAwareOperation>().runTest();
  });
}

/// A helper for asserting against a new component that implements [ValueTest].
class _GetValue<T extends ValueTest> {
  const _GetValue();

  Future<Null> runTest() async {
    final fixture = await new NgTestBed<T>().create();
    await fixture.update(expectAsync1((ValueTest comp) {
      expect(comp.child.value, comp.expected);
    }));
  }
}

@Component(
  selector: 'child',
  template: r'{{value}}',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'<child [value]="10"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="'string'"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="\'a\n\nb\'"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestNewLines implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  @override
  get expected => 'a\n\nb';
}

@Component(
  selector: 'test',
  directives: const [ChildComponent],
  template: '<child [value]="10 + 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="10 - 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="10 * 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="10 / 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="11 % 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="1 == 1"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="1 != 1"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="1 === 1"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="1 !== 1"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="1 < 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="2 > 1"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="1 <= 2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="2 >= 1"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="true && false"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="val1 || val2"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="!true"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: '<child [value]="!!true"></child>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="1 > 2 ? 'yes' : 'no'"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="map['foo']"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="list[1]"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="list.length"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="list.length.isEven"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="list.toList().length.isEven"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="null"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="map?.keys"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  directives: const [ChildComponent],
  template: r'''<child [value]="map?.keys ?? 'Hello'"></child>''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestNullAwareOperation implements ValueTest {
  @ViewChild(ChildComponent)
  @override
  ChildComponent child;

  get map => null;

  @override
  get expected => 'Hello';
}
