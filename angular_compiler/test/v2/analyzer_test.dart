import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v2/analyzer.dart';
import 'package:angular_compiler/v2/testing.dart';

void main() {
  group('NullableDartType', () {
    test('a missing type ("null") should not be explicitly anything', () {
      DartType? noType;
      expect(noType.isExplicitlyNonNullable, isFalse);
      expect(noType.isExplicitlyNullable, isFalse);
    });

    Future<void> testDynamicIsNotExplicit({
      required bool enableNullSafety,
    }) async {
      final lib = await resolve(
        '''
        ${enableNullSafety ? '// @dart=2.9' : ''}
        dynamic topLevelField;
        ''',
        includeAngularDeps: false,
      );
      final field = lib.library.topLevelElements.last as VariableElement;
      expect(field.type.isExplicitlyNullable, isFalse);
      expect(field.type.isExplicitlyNonNullable, isFalse);
    }

    group('on opted-in code:', () {
      test('dynamic should not be explicitly anything', () async {
        await (testDynamicIsNotExplicit(enableNullSafety: true));
      });

      test('a non-nullable type should be explicitly non-nullable', () async {
        final lib = await resolve(
          '''
          String topLevelField;
          ''',
          includeAngularDeps: false,
        );
        final field = lib.library.topLevelElements.last as VariableElement;
        expect(field.type.isExplicitlyNullable, isFalse);
        expect(field.type.isExplicitlyNonNullable, isTrue);
      });

      test('a nullable type should be explicitly nullable', () async {
        final lib = await resolve(
          '''
          String? topLevelField;
          ''',
          includeAngularDeps: false,
        );
        final field = lib.library.topLevelElements.last as VariableElement;
        expect(field.type.isExplicitlyNullable, isTrue);
        expect(field.type.isExplicitlyNonNullable, isFalse);
      });

      test('a nullable FutureOr should be explicitly nullable', () async {
        final lib = await resolve(
          '''
          import 'dart:async';
          FutureOr<String?> topLevelField;
          ''',
          includeAngularDeps: false,
        );
        final field = lib.library.topLevelElements.last as VariableElement;
        expect(field.type.isExplicitlyNullable, isTrue);
        expect(field.type.isExplicitlyNonNullable, isFalse);
      });
    });

    group('on opted-out code:', () {
      test('dynamic should not be explicitly anything', () async {
        await (testDynamicIsNotExplicit(enableNullSafety: false));
      });

      test('a legacy type should not be explicitly anything', () async {
        final lib = await resolve(
          '''
          // @dart=2.9
          String topLevelField;
          ''',
          includeAngularDeps: false,
        );
        final field = lib.library.topLevelElements.last as VariableElement;
        expect(field.type.isExplicitlyNullable, isFalse);
        expect(field.type.isExplicitlyNonNullable, isFalse);
      });

      test('a legacy FutureOr should not explicitly anything', () async {
        final lib = await resolve(
          '''
          // @dart=2.9
          import 'dart:async';
          FutureOr<String> topLevelField;
          ''',
          includeAngularDeps: false,
        );
        final field = lib.library.topLevelElements.last as VariableElement;
        expect(field.type.isExplicitlyNullable, isFalse);
        expect(field.type.isExplicitlyNonNullable, isFalse);
      });
    });
  });
}
