@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../../src/compile.dart';
import '../../src/resolve.dart';

// TODO(leonsenft): remove when `Typed` is exported publicly.
final typedImport =
    angular.replaceFirst('angular.dart', 'src/core/metadata/typed.dart');

Future<TypedElement> parse(String source) async {
  final amendedSource = 'import "$typedImport";\n$source';
  final element = await resolveClass(amendedSource);
  final typedReader = TypedReader(element);
  final typedValue = element.metadata.first.computeConstantValue();
  return typedReader.parse(typedValue);
}

void main() {
  group('parses', () {
    group('Typed()', () {
      test('with single concrete type argument', () async {
        final typedElement = await parse('''
          const typed = Typed<List<String>>();

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('String', 'dart:core'),
            ]),
          ),
        );
      });
      test('with multiple concrete type arguments', () async {
        final typedElement = await parse('''
          const typed = Typed<Map<String, Object>>();

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('Map', 'dart:core', [
              TypeLink('String', 'dart:core'),
              TypeLink('Object', 'dart:core'),
            ]),
          ),
        );
      });
      test('with nested concrete type arguments', () async {
        final typedElement = await parse('''
          const typed = Typed<List<List<String>>>();

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('List', 'dart:core', [
                TypeLink('String', 'dart:core'),
              ]),
            ]),
          ),
        );
      });
      test('with "on"', () async {
        final typedElement = await parse('''
          const typed = Typed<List<String>>(on: 'strings');

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('String', 'dart:core'),
            ]),
            on: 'strings',
          ),
        );
      });
    });

    group('Typed.of()', () {
      test('with single Symbol argument', () async {
        final typedElement = await parse('''
          const typed = Typed<List>.of([#X]);

          @typed
          class Example<X> {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('X', null),
            ]),
          ),
        );
      });
      test('with single Type argument', () async {
        final typedElement = await parse('''
          const typed = Typed<List>.of([int]);

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('int', 'dart:core'),
            ]),
          ),
        );
      });
      test('with single Typed argument', () async {
        final typedElement = await parse('''
          const typed = Typed<List>.of([Typed<List<int>>()]);

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('List', 'dart:core', [
                TypeLink('int', 'dart:core'),
              ]),
            ]),
          ),
        );
      });
      test('with nested Typed argument', () async {
        final typedElement = await parse('''
          const typed = Typed<List>.of([Typed<Map>.of([String, #X])]);

          @typed
          class Example<X> {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('Map', 'dart:core', [
                TypeLink('String', 'dart:core'),
                TypeLink('X', null),
              ]),
            ]),
          ),
        );
      });
      test('with "on"', () async {
        final typedElement = await parse('''
          const typed = Typed<List>.of([#X], on: 'flow');

          @typed
          class Example<X> {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('List', 'dart:core', [
              TypeLink('X', null),
            ]),
            on: 'flow',
          ),
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
    test('if "Typed.on" is specified anywhere other than the root', () async {
      await compilesExpecting(
        '''
        import '$typedImport';
        const typed = Typed<List>.of([
          Typed<List>.of([#X], on: 'foo'),
        ]);

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          contains(
              'The "on" argument is only supported on the root "Typed" of a '
              '"Typed" expression')
        ],
      );
    });

    test('if a directive with bounded type parameters is typed', () async {
      await compilesExpecting(
        '''
        import '$typedImport';
        class GenericComponent<T extends num> {}
        const typed = Typed<GenericComponent<int>>();

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          contains("Generic type arguments aren't supported for components and "
              'directives with bounded type parameters.')
        ],
      );
    });
  });
}
