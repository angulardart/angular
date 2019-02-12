import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../../src/resolve.dart';

void main() {
  group('should parse dependencies from', () {
    final reader = const DependencyReader();
    LibraryElement library;

    setUpAll(() async {
      library = await resolveLibrary(r'''
        @Injectable()
        external Example createExample0();

        @Injectable()
        external Example createExample1(Engine engine);

        @Injectable()
        external Example createExample2(Engine engine, {Logger logger});

        @Injectable()
        external Example createExampleHost(@Host() Engine engine);

        @Injectable()
        external Example createExampleSelf(@Self() Engine engine);

        @Injectable()
        external Example createExampleSkipSelf(@SkipSelf() Engine engine);

        @Injectable()
        external Example createExampleOptional(@Optional() Engine engine);

        @Injectable()
        external Example createExampleInject(@Inject(someToken) Engine engine);

        @Injectable()
        external Example createExampleInjectToken(@someToken Engine engine);

        @Injectable()
        external Example createExampleDynamic(@Inject(Engine) engine);

        const someToken = const OpaqueToken('someToken');

        @Injectable()
        class Example { /* Has a default constructor */ }

        @Injectable()
        abstract class Engine {
          // Has a factory constructor.
          external factory Engine();
        }

        @Injectable()
        class Logger {
          // Has a named constructor.
          Logger.named();
        }

        @Injectable()
        class BadField {
          final String fieldA;

          BadField(this._fieldA);
        }
      ''');
    });

    ClassElement classNamed(String name) => library.getType(name);

    FunctionElement functionNamed(String name) =>
        library.definingCompilationUnit.functions
            .firstWhere((e) => e.name == name);

    test('a function with no parameters', () {
      final function = functionNamed('createExample0');
      final deps = reader.parseDependencies(function);
      expect(deps.bound, const TypeMatcher<FunctionElement>());
      expect(deps.positional, isEmpty);
      expect(deps.named, isEmpty);
    });

    test('a function with one parameter', () {
      final function = functionNamed('createExample1');
      final deps = reader.parseDependencies(function);
      expect(deps.bound, const TypeMatcher<FunctionElement>());
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
        ),
      ]);
      expect(deps.named, isEmpty);
    });

    test('a function with two parameters, of which one is named', () {
      final function = functionNamed('createExample2');
      final deps = reader.parseDependencies(function);
      expect(deps.bound, const TypeMatcher<FunctionElement>());
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
        ),
      ]);
      expect(deps.named, isEmpty, reason: 'Named arguments not supported yet');
    });

    test('a function with a parameter annotated with @Host', () {
      final function = functionNamed('createExampleHost');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
          host: true,
        ),
      ]);
    });

    test('a function with a parameter annotated with @Optional', () {
      final function = functionNamed('createExampleOptional');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
          optional: true,
        ),
      ]);
    });

    test('a function with a parameter annotated with @Self', () {
      final function = functionNamed('createExampleSelf');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
          self: true,
        ),
      ]);
    });

    test('a function with a parameter annotated with @SkipSelf', () {
      final function = functionNamed('createExampleSkipSelf');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
          skipSelf: true,
        ),
      ]);
    });

    test('a function with a parameter annotated with @Inject', () {
      final function = functionNamed('createExampleInject');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          OpaqueTokenElement(
            'someToken',
            isMultiToken: false,
            classUrl: TypeLink(
              'OpaqueToken',
              ''
                  'package:angular'
                  '/src/core/di/opaque_token.dart',
            ),
          ),
          type: TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
        ),
      ]);
    });

    test('a function with a parameter annotated with an OpaqueToken', () {
      final function = functionNamed('createExampleInjectToken');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          OpaqueTokenElement(
            'someToken',
            isMultiToken: false,
            classUrl: TypeLink(
              'OpaqueToken',
              ''
                  'package:angular'
                  '/src/core/di/opaque_token.dart',
            ),
          ),
          type: TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
        ),
      ]);
    });

    test('a function with an untyped parameter annotated with @Inject', () {
      final function = functionNamed('createExampleDynamic');
      final deps = reader.parseDependencies(function);
      expect(deps.positional, [
        DependencyElement(
          TypeTokenElement(
            TypeLink('Engine', 'asset:test_lib/lib/test_lib.dart'),
          ),
          type: TypeTokenElement.$dynamic,
        ),
      ]);
    });

    test('a class with a default constructor', () {
      final clazz = classNamed('Example');
      final deps = reader.parseDependencies(clazz);
      expect(deps.bound, const TypeMatcher<ConstructorElement>());
      expect(deps.positional, isEmpty);
      expect(deps.named, isEmpty);
    });

    test('an abstract class with a public factory constructor', () {
      final clazz = classNamed('Engine');
      final deps = reader.parseDependencies(clazz);
      expect(deps.bound, const TypeMatcher<ConstructorElement>());
      expect(deps.positional, isEmpty);
      expect(deps.named, isEmpty);
    });

    test('a class with a named constructor', () {
      final clazz = classNamed('Logger');
      final deps = reader.parseDependencies(clazz);
      expect(deps.bound, const TypeMatcher<ConstructorElement>());
      expect(deps.positional, isEmpty);
      expect(deps.named, isEmpty);
    });
  });
}
