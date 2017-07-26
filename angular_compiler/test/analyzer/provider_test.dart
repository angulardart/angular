import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  group('Provider', () {
    const reader = const ProviderReader();

    LibraryElement testLib;

    setUpAll(() async {
      testLib = await resolveLibrary(r'''
        /// An example of an injectable service with a concerete constructor.
        @Injectable()
        class Example {}

        @Injectable()
        class ExampleSuper extends Example {}

        /// Implicitly "const Provider(Example)".
        const implicitTypeProvider = Example;

        /// A typed variant of the previous field.
        const explicitTypeProvider = const Provider(Example);

        /// Example of using "useClass: ...".
        const useClassProvider = const Provider(
          Example,
          useClass: ExampleSuper,
        );

        /// Example of using "useFactory: ...".
        const useFactoryProvider = const Provider(
          Example,
          useFactory: createExample,
        );

        @Injectable()
        Example createExample() => new Example();

        /// Example of using "useValue: ..."
        const useValueProvider = const Provider(
          Duration,
          useValue: const Duration(seconds: 5),
        );

        /// Example of using OpaqueToken.
        const tokenProvider = const Provider(
          const OpaqueToken('someConfig'),
          useClass: Example,
        );
      ''');
    });

    ProviderElement provider(String name) {
      final variable = testLib.definingCompilationUnit.topLevelVariables
          .firstWhere((e) => e.name == name);
      return reader.parseProvider(variable.computeConstantValue());
    }

    group('token should be analyzed as', () {
      test('a type (implicit provider)', () {
        final aProvider = provider('implicitTypeProvider');
        expect(aProvider.token, const isInstanceOf<TypeTokenElement>());
        final aTypeToken = aProvider.token as TypeTokenElement;
        expect('${aTypeToken.url}', 'asset:test_lib/lib/test_lib.dart#Example');
      });

      test('a type (explicit provider)', () {
        final aProvider = provider('explicitTypeProvider');
        expect(aProvider.token, const isInstanceOf<TypeTokenElement>());
        final aTypeToken = aProvider.token as TypeTokenElement;
        expect('${aTypeToken.url}', 'asset:test_lib/lib/test_lib.dart#Example');
      });

      test('an opaque token', () {
        final aProvider = provider('tokenProvider');
        expect(aProvider.token, const isInstanceOf<OpaqueTokenElement>());
        final anOpaqueToken = aProvider.token as OpaqueTokenElement;
        expect(anOpaqueToken.identifier, 'someConfig');
      });
    });

    group('configuration should be analyzed as', () {
      // const [Example]
      test('type (implicit provider) -> create new instance of type', () {
        final aProvider = provider(
          'implicitTypeProvider',
        ) as UseClassProviderElement;
        expect(
          '${aProvider.useClass}',
          'asset:test_lib/lib/test_lib.dart#Example',
        );
      });

      // const [const Provider(Example)]
      test('type (explicit provider) -> create a new instance of type', () {
        final aProvider = provider(
          'explicitTypeProvider',
        ) as UseClassProviderElement;
        expect(
          '${aProvider.useClass}',
          'asset:test_lib/lib/test_lib.dart#Example',
        );
      });

      // const [const Provider(Example, useClass: ExampleSuper)]
      test('useClass -> create a new instance of provided type', () {
        final aProvider = provider(
          'useClassProvider',
        ) as UseClassProviderElement;
        expect(
          '${aProvider.useClass}',
          'asset:test_lib/lib/test_lib.dart#ExampleSuper',
        );
      });

      // const [const Provider(Example, useFactory: createExample)]
      test('useFactory -> invokes a top-level or static method', () {
        final aProvider = provider(
          'useFactoryProvider',
        ) as UseFactoryProviderElement;
        expect(
          '${aProvider.useFactory}',
          'asset:test_lib/lib/test_lib.dart#createExample',
        );
      });

      test('useValue -> use a constant expression', () {
        final aProvider = provider(
          'useValueProvider',
        ) as UseValueProviderElement;
        expect(
          '${aProvider.useValue.source}',
          'dart:core#Duration',
        );
        expect(
          mapMap(
            aProvider.useValue.namedArguments,
            value: (_, v) => new ConstantReader(v).anyValue,
          ),
          {
            'seconds': 5,
          },
        );
      });

      // TODO(matanl): Add tests for dependencies/parameter annotations.
    });
  });
}
