@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../../src/compile.dart';
import '../../src/resolve.dart';

void main() {
  // TODO(leonsenft): remove when `Typed` is exported by package:angular.
  final typedImport =
      angular.replaceFirst('angular.dart', 'src/core/metadata/typed.dart');

  group('parses', () {
    group('Typed()', () {
      test('with single concrete type argument', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<List<String>>();

          @typed
          class Example {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('List', 'dart:core', [
            TypeLink('String', 'dart:core'),
          ]),
        );
      });
      test('with multiple concrete type arguments', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<Map<String, Object>>();

          @typed
          class Example {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('Map', 'dart:core', [
            TypeLink('String', 'dart:core'),
            TypeLink('Object', 'dart:core'),
          ]),
        );
      });
      test('with nested concrete type arguments', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<List<List<String>>>();

          @typed
          class Example {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('List', 'dart:core', [
            TypeLink('List', 'dart:core', [
              TypeLink('String', 'dart:core'),
            ]),
          ]),
        );
      });
    });

    group('Typed.of()', () {
      test('with single Symbol argument', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<List>.of([#X]);

          @typed
          class Example<X> {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('List', 'dart:core', [
            TypeLink('X', null),
          ]),
        );
      });
      test('with single Type argument', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<List>.of([int]);

          @typed
          class Example {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('List', 'dart:core', [
            TypeLink('int', 'dart:core'),
          ]),
        );
      });
      test('with single Typed argument', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<List>.of([Typed<List<int>>()]);

          @typed
          class Example {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('List', 'dart:core', [
            TypeLink('List', 'dart:core', [
              TypeLink('int', 'dart:core'),
            ]),
          ]),
        );
      });
      test('with nested Typed argument', () async {
        final example = await resolveClass('''
          import '$typedImport';
          const typed = Typed<List>.of([Typed<Map>.of([String, #X])]);

          @typed
          class Example<X> {}
        ''');
        final typedReader = TypedReader(example);
        final typedValue = example.metadata.first.computeConstantValue();
        expect(
          typedReader.parse(typedValue),
          TypeLink('List', 'dart:core', [
            TypeLink('Map', 'dart:core', [
              TypeLink('String', 'dart:core'),
              TypeLink('X', null),
            ]),
          ]),
        );
      });
    });
  });

  group('throws', () {
    Future<void> parseTyped(LibraryElement element) async {
      final example = element.getType('Example');
      final typedReader = TypedReader(example);
      final typedValue = example.metadata.first.computeConstantValue();
      typedReader.parse(typedValue);
    }

    test('if expression isn\'t of type "Typed"', () async {
      await compilesExpecting(
        '''
        const typed = 12;

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          'Expected an expression of type "Typed", but got "int"',
        ],
      );
    });
    test('if a concrete type is used as a type argument of "Typed"', () async {
      await compilesExpecting(
        '''
        import '$typedImport';
        const typed = Typed<int>();

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          allOf(
            contains('Expected a generic type'),
            contains('got concrete type "int"'),
          )
        ],
      );
    });
    test('if a non-existent type parameter is flowed', () async {
      await compilesExpecting(
        '''
        import '$typedImport';
        const typed = Typed<List>.of([#X]);

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          allOf(
            contains('Attempted to flow a type parameter "X"'),
            contains('"Example" declares no such generic type parameter'),
          ),
        ],
      );
    });
    test("if a type argument isn't a supported type", () async {
      await compilesExpecting(
        '''
        import '$typedImport';
        const typed = Typed<List>.of([12]);

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          allOf([
            contains('Expected a type argument of "Typed" to be of'),
            contains('Got an expression of type "int"'),
          ]),
        ],
      );
    });
  });
}
