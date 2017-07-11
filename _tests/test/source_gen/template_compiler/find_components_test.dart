@TestOn('vm')

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/source_gen/template_compiler/find_components.dart';

void main() {
  group('should be mock-like', () {
    test("with 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent('''
        @Component()
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

        @Component()
        class MockLikeComponent extends MockLikeBase {}''');
      expect(normalizedComponent.component.analyzedClass.isMockLike, true);
    });

    test("with mixed-in 'noSuchMethod' implementation", () async {
      final normalizedComponent = await resolveAndFindComponent('''
        class MockLikeMixin {
          noSuchMethod(Invocation invocation) => null;
        }

        @Component()
        class MockLikeComponent extends Object with MockLikeMixin {}''');
      expect(normalizedComponent.component.analyzedClass.isMockLike, true);
    });
  });

  test('should not be mock-like', () async {
    final normalizedComponent = await resolveAndFindComponent('''
      @Component()
      class NotMockLikeComponent {}''');
    expect(normalizedComponent.component.analyzedClass.isMockLike, false);
  });
}

Future<NormalizedComponentWithViewDirectives> resolveAndFindComponent(
  String source,
) async {
  final testAssetId = new AssetId('find_components_test', 'lib/test.dart');
  final resolver = await resolveSource(
    '''
    import 'package:angular/angular.dart';
    $source''',
    inputId: testAssetId,
  );
  final artifacts =
      findComponentsAndDirectives(resolver.getLibrary(testAssetId));
  return artifacts.components.first;
}
