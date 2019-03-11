@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1666_named_arguments_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support default named arguments', () async {
    final testBed = NgTestBed.forComponent<TestNamedArgsWithDefaultValue1>(
      ng.TestNamedArgsWithDefaultValue1NgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
    expect(fixture.assertOnlyInstance.captured, ['bar']);
  });

  test('should support default named arguments with a tear-off', () async {
    final testBed = NgTestBed.forComponent<TestNamedArgsWithDefaultValue2>(
      ng.TestNamedArgsWithDefaultValue2NgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
    expect(fixture.assertOnlyInstance.captured, ['bar']);
  });

  test('should support passing a component field as positional arg', () async {
    final testBed = NgTestBed.forComponent<TestPositionalArgsFromComponent>(
      ng.TestPositionalArgsFromComponentNgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
    expect(fixture.assertOnlyInstance.captured, ['bar']);
  });

  test('should support passing a component field as an arg', () async {
    final testBed = NgTestBed.forComponent<TestNamedArgsFromComponentField>(
      ng.TestNamedArgsFromComponentFieldNgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
    expect(fixture.assertOnlyInstance.captured, ['bar']);
  });

  test('should support passing a literal value as an arg', () async {
    final testBed = NgTestBed.forComponent<TestNamedArgsFromLiteralValue>(
      ng.TestNamedArgsFromLiteralValueNgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
    expect(fixture.assertOnlyInstance.captured, ['bar']);
  });

  test('should support passing a template local variable as an arg', () async {
    final testBed = NgTestBed.forComponent<TestNamedArgsFromLocalValue>(
      ng.TestNamedArgsFromLocalValueNgFactory,
    );
    final fixture = await testBed.create();
    await fixture.update((_) {
      fixture.rootElement.querySelector('button').click();
    });
    expect(fixture.assertOnlyInstance.captured, ['bar']);
  });
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo()"></button>',
)
class TestNamedArgsWithDefaultValue1 {
  final captured = <String>[];

  void foo({String bar = 'bar'}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo"></button>',
)
class TestNamedArgsWithDefaultValue2 {
  final captured = <String>[];

  void foo({String bar = 'bar'}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo(field)"></button>',
)
class TestPositionalArgsFromComponent {
  final field = 'bar';
  final captured = <String>[];

  void foo(String bar) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'<button (click)="foo(bar: field)"></button>',
)
class TestNamedArgsFromComponentField {
  final field = 'bar';
  final captured = <String>[];

  void foo({String bar}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  template: r'''<button (click)="foo(bar: 'bar')"></button>''',
)
class TestNamedArgsFromLiteralValue {
  final captured = <String>[];

  void foo({String bar}) {
    captured.add(bar);
  }
}

@Component(
  selector: 'test',
  directives: [NgFor],
  template: r'''
    <ng-container *ngFor="let item of items">
      <button (click)="foo(bar: item)"></button>
    </ng-container>
  ''',
)
class TestNamedArgsFromLocalValue {
  final items = ['bar'];
  final captured = <String>[];

  void foo({String bar}) {
    captured.add(bar);
  }
}
