import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'additional_expression_lib.dart' as lib;
import 'additional_expression_test.template.dart' as ng;

/// Tests written to for correctness of `parse_expressions_with_analyzer`.
///
/// There were not other test cases that caught these failures in our repo.
void main() {
  tearDown(disposeAnyRunningTest);

  test('should parse identifiers from prefixed exports', () async {
    final fixture = await NgTestBed(
      ng.createTestPrefixedExportsFactory(),
    ).create();
    expect(
      fixture.text,
      allOf(
        contains('lib.ExternalStaticClass.returnsA(): A'),
        contains('lib.ExternalStaticClass.valueB: staticB'),
        contains('lib.toUppercase(name): BOB'),
        contains('lib.valueB: topLevelB'),
      ),
    );
  });

  group('should parse non-root assignment expressions in outputs', () {
    late NgTestFixture<TestNonRootAssignment> fixture;

    setUp(() async {
      fixture = await NgTestBed(
        ng.createTestNonRootAssignmentFactory(),
      ).create();
    });

    test('(a = event)', () async {
      expect(fixture.assertOnlyInstance.a, isNull);

      await fixture.update(
        (_) => fixture.rootElement.querySelectorAll('button')[0].click(),
      );

      expect(fixture.assertOnlyInstance.a, isNotNull);
    });

    test('a = b = event', () async {
      expect(fixture.assertOnlyInstance.a, isNull);
      expect(fixture.assertOnlyInstance.b, isNull);

      await fixture.update(
        (_) => fixture.rootElement.querySelectorAll('button')[1].click(),
      );

      expect(fixture.assertOnlyInstance.a, isNotNull);
      expect(fixture.assertOnlyInstance.a, fixture.assertOnlyInstance.b);
    });

    test('a = c(b = event)', () async {
      expect(fixture.assertOnlyInstance.a, isNull);
      expect(fixture.assertOnlyInstance.b, isNull);

      await fixture.update(
        (_) => fixture.rootElement.querySelectorAll('button')[2].click(),
      );

      expect(fixture.assertOnlyInstance.a, isNotNull);
      expect(fixture.assertOnlyInstance.a, fixture.assertOnlyInstance.b);
    });
  });

  test('should parse null-aware method invocations', () async {
    final fixture = await NgTestBed(
      ng.createTestNullAwareFunctionsFactory(),
    ).create();
    expect(
      fixture.text,
      allOf(
        contains('Local MODEL: ""'),
        contains('Static MODEL: ""'),
        contains('Prefixed Static STRING: ""'),
        contains('Prefixed Field STRING: ""'),
        contains('NgFor MODEL: ""'),
      ),
    );
  });
}

@Component(
  selector: 'test-prefixed-exports',
  exports: [
    lib.ExternalStaticClass,
    lib.toUppercase,
    lib.valueB,
  ],
  template: r'''
    lib.ExternalStaticClass.returnsA(): {{lib.ExternalStaticClass.returnsA()}}

    lib.ExternalStaticClass.valueB:     {{lib.ExternalStaticClass.valueB}}

    lib.toUppercase(name):              {{lib.toUppercase(name)}}

    lib.valueB:                         {{lib.valueB}}
  ''',
)
class TestPrefixedExports {
  var name = 'Bob';
}

@Component(
  selector: 'test-non-root-assignment',
  template: r'''
    <button (click)="(a = $event)"></button>
    <button (click)="a = b = $event"></button>
    <button (click)="a = c(b = $event)"></button>
  ''',
)
class TestNonRootAssignment {
  Object? a;
  Object? b;

  Object c(Object c) => c;
}

@Component(
  selector: 'test-null-aware-functions',
  directives: [
    NgFor,
  ],
  exports: [
    lib.ExternalStaticClass,
    lib.nullString,
  ],
  template: r'''
    Local MODEL:            "{{model?.getName()}}"
    Static MODEL:           "{{staticModel?.getName()}}"
    Prefixed Static STRING: "{{lib.ExternalStaticClass.nullString?.toUpperCase()}}"
    Prefixed Field STRING:  "{{lib.nullString?.toUpperCase()}}"
    <ng-container *ngFor="let model of models">
      NgFor MODEL:          "{{model?.getName()}}"
    </ng-container>
  ''',
)
class TestNullAwareFunctions {
  static Model? staticModel;

  Model? model;
  final models = <Model?>[null];
}

class Model {
  String getName() => throw UnimplementedError();
}
