@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../../src/compile.dart';
import '../../src/resolve.dart';

const testImport = 'asset:test_lib/lib/test_lib.dart';

Future<TypedElement> parse(String source) async {
  final amendedSource = '''
    @Component()
    class GenericComponent<T> {}

    @Directive()
    class GenericDirective<K, V> {}

    $source
  ''';
  final element = await resolveClass(amendedSource, 'Example');
  final typedReader = TypedReader(element);
  final typedValue = element.metadata
      .firstWhere((annotation) => annotation.element.name == 'typed')
      .computeConstantValue();
  return typedReader.parse(typedValue);
}

void main() {
  group('parses', () {
    group('Typed()', () {
      test('with single concrete type argument', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericComponent<String>>();

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
              TypeLink('String', 'dart:core'),
            ]),
          ),
        );
      });
      test('with multiple concrete type arguments', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericDirective<String, Object>>();

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericDirective', testImport, [
              TypeLink('String', 'dart:core'),
              TypeLink('Object', 'dart:core'),
            ]),
          ),
        );
      });
      test('with nested concrete type arguments', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericComponent<List<String>>>();

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
              TypeLink('List', 'dart:core', [
                TypeLink('String', 'dart:core'),
              ]),
            ]),
          ),
        );
      });
      test('with "on"', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericComponent<String>>(on: 'strings');

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
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
          const typed = Typed<GenericComponent>.of([#X]);

          @typed
          class Example<X> {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
              TypeLink('X', null),
            ]),
          ),
        );
      });
      test('with single Type argument', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericComponent>.of([int]);

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
              TypeLink('int', 'dart:core'),
            ]),
          ),
        );
      });
      test('with single Typed argument', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericComponent>.of([Typed<List<int>>()]);

          @typed
          class Example {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
              TypeLink('List', 'dart:core', [
                TypeLink('int', 'dart:core'),
              ]),
            ]),
          ),
        );
      });
      test('with nested Typed argument', () async {
        final typedElement = await parse('''
          const typed = Typed<GenericComponent>.of([
            Typed<Map>.of([String, #X]),
          ]);

          @typed
          class Example<X> {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
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
          const typed = Typed<GenericComponent>.of([#X], on: 'flow');

          @typed
          class Example<X> {}
        ''');
        expect(
          typedElement,
          TypedElement(
            TypeLink('GenericComponent', testImport, [
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
        @Directive()
        class ConcreteDirective {}
        const typed = Typed<ConcreteDirective>();

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          allOf(
            contains('Expected a generic type'),
            contains('got concrete type "ConcreteDirective"'),
          )
        ],
      );
    });
    test('if a non-existent type parameter is flowed', () async {
      await compilesExpecting(
        '''
        @Component()
        class GenericComponent<T> {}
        const typed = Typed<GenericComponent>.of([#X]);

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
        @Component()
        class GenericComponent<T> {}
        const typed = Typed<GenericComponent>.of([12]);

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
        @Component()
        class GenericComponent<T> {}
        const typed = Typed<GenericComponent>.of([
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

    test('if "Typed" isn\'t applied to a directive', () async {
      await compilesExpecting(
        '''
        const typed = Typed<List<int>>();

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          contains(
              'Expected a "Typed" expression with a "Component" or "Directive" '
              'annotated type, but got "Typed<List>"')
        ],
      );
    });

    test('if a private type argument is used', () async {
      await compilesExpecting(
        '''
        @Component()
        class GenericComponent<T> {}
        class _Private {}
        const typed = Typed<GenericComponent<_Private>>();

        @typed
        class Example {}
        ''',
        parseTyped,
        errors: [
          contains(
              'Directive type arguments must be public, but "GenericComponent" '
              'was given private type argument "_Private" by "Example".')
        ],
      );
    });
  });
}
