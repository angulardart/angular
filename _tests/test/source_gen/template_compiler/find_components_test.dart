// @dart=2.9

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v2/context.dart';

import '../../resolve_util.dart';

void main() {
  setUp(() {
    CompileContext.overrideForTesting(CompileContext.forTesting(
      emitNullSafeCode: false,
    ));
  });

  void mockLikeTests({@required bool nullSafe}) {
    setUp(() {
      if (nullSafe) {
        CompileContext.overrideForTesting(CompileContext.forTesting(
          emitNullSafeCode: true,
        ));
      }
    });
    final libHeader = nullSafe ? '' : '// @dart=2.9';
    test("with 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent(
        '''
        $libHeader
        @Component(selector: 'not-blank')
        class MockLikeComponent {
          noSuchMethod(Invocation invocation) => null;
        }''',
      );

      final isMockLike = normalizedComponent.component.analyzedClass.isMockLike;
      if (nullSafe) {
        expect(isMockLike, false);
      } else {
        expect(isMockLike, true);
      }
    });

    test("with inherited 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent(
        '''
        $libHeader
        class MockLikeBase {
          noSuchMethod(Invocation invocation) => null;
        }

        @Component(selector: 'not-blank')
        class MockLikeComponent extends MockLikeBase {}''',
      );

      final isMockLike = normalizedComponent.component.analyzedClass.isMockLike;
      if (nullSafe) {
        expect(isMockLike, false);
      } else {
        expect(isMockLike, true);
      }
    });

    test("with mixed-in 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent(
        '''
        $libHeader
        class MockLikeMixin {
          noSuchMethod(Invocation invocation) => null;
        }

        @Component(selector: 'not-blank')
        class MockLikeComponent extends Object with MockLikeMixin {}''',
      );

      final isMockLike = normalizedComponent.component.analyzedClass.isMockLike;
      if (nullSafe) {
        expect(isMockLike, false);
      } else {
        expect(isMockLike, true);
      }
    });
  }

  group('should be mock-like', () {
    mockLikeTests(nullSafe: false);
  });

  group('should never be mock-like when opted-in to null-safety', () {
    mockLikeTests(nullSafe: true);
  });

  test('should not be mock-like', () async {
    final normalizedComponent = await resolveAndFindComponent(
      '''
      // @dart=2.9
      @Component(selector: 'not-blank')
      class NotMockLikeComponent {}''',
    );
    expect(normalizedComponent.component.analyzedClass.isMockLike, false);
  });

  group('Generic type parameter', () {
    test('should resolve to dynamic when unspecified', () async {
      final normalizedComponent = await resolveAndFindComponent('''
        @Component(selector: 'not-blank')
        class TestComponent<T> {
          @Input()
          T value;
        }''');
      expect(normalizedComponent.component.inputTypes['value'].name, 'dynamic');
    });

    test('should resolve to dynamic when unspecified on supertype', () async {
      final normalizedComponent = await resolveAndFindComponent('''
        abstract class Base<T> {
          @Input()
          T value;
        }

        @Component(selector: 'not-blank')
        class TestComponent extends Base {}
      ''');
      expect(normalizedComponent.component.inputTypes['value'].name, 'dynamic');
    });

    test('should resolve bounded type', () async {
      final normalizedComponent = await resolveAndFindComponent('''
        @Component(selector: 'not-blank')
        class TestComponent<T extends String> {
          @Input()
          T value;
        }''');
      expect(normalizedComponent.component.inputTypes['value'].name, 'String');
    });

    test('should resolve bounded type on supertype', () async {
      final normalizedComponent = await resolveAndFindComponent('''
        abstract class Base<T> {
          @Input()
          T value;
        }

        @Component(selector: 'not-blank')
        class TestComponent<S extends String> extends Base<S> {}
      ''');
      expect(normalizedComponent.component.inputTypes['value'].name, 'String');
    });

    test('should resolve to specified type', () async {
      final normalizedComponent = await resolveAndFindComponent('''
        abstract class Base<T> {
          @Input()
          T value;
        }

        @Component(selector: 'not-blank')
        class TestComponent extends Base<String> {}
      ''');
      expect(normalizedComponent.component.inputTypes['value'].name, 'String');
    });
  });
}
