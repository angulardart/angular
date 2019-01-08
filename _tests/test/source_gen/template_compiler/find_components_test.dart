@TestOn('vm')
import 'package:test/test.dart';

import '../../resolve_util.dart';

void main() {
  group('should be mock-like', () {
    test("with 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent('''
        @Component(selector: 'not-blank')
        class MockLikeComponent {
          noSuchMethod(Invocation invocation) => null;
        }''');
      expect(normalizedComponent.component.analyzedClass.isMockLike, true);
    });

    test("with inherited 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent('''
        class MockLikeBase {
          noSuchMethod(Invocation invocation) => null;
        }

        @Component(selector: 'not-blank')
        class MockLikeComponent extends MockLikeBase {}''');
      expect(normalizedComponent.component.analyzedClass.isMockLike, true);
    });

    test("with mixed-in 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent('''
        class MockLikeMixin {
          noSuchMethod(Invocation invocation) => null;
        }

        @Component(selector: 'not-blank')
        class MockLikeComponent extends Object with MockLikeMixin {}''');
      expect(normalizedComponent.component.analyzedClass.isMockLike, true);
    });
  });

  test('should not be mock-like', () async {
    final normalizedComponent = await resolveAndFindComponent('''
      @Component(selector: 'not-blank')
      class NotMockLikeComponent {}''');
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
