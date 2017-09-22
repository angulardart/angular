import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/angular_compiler.dart';

import '../../src/constants.dart';
import '../../src/resolve.dart';

void main() {
  group('should parse provider from', () {
    List<DartObject> providers;
    const reader = const ProviderReader();

    ClassElement $Example;
    ClassElement $ExamplePrime;
    ClassElement $DependencyA;
    ClassElement $DependencyB;
    FunctionElement $createExample;

    setUpAll(() async {
      final testLib = await resolveLibrary(r'''
        @exampleModule
        @newModuleA
        @newModuleB
        @Injectable()
        class Example {}

        @Injectable()
        class ExamplePrime extends Example {}

        class DependencyA {}
        class DependencyB {}

        @Injectable()
        Example createExample(DependencyA a) => new ExamplePrime();

        const exampleToken = const OpaqueToken('exampleToken');

        const exampleModule = const [
          // [0] Implicit Provider(Type)
          Example,

          // [1] Explicit Provider(Type)
          const Provider(Example),

          // [2] Explicit Provider(Type, useClass: Type)
          const Provider(Example, useClass: ExamplePrime),

          // [3] Explicit Provider(Type, useFactory: factoryForType),
          const Provider(Example, useFactory: createExample),

          // [4] Explicit Provider(Type, useFactory, deps: ...)
          const Provider(
            Example,
            useFactory: createExample,
            deps: const [DependencyB],
          ),

          // [5] Explicit Provider(Type, useValue)
          const Provider(Duration, useValue: const Duration(seconds: 5)),

          // [6] Explicit Provider w/ OpaqueToken
          const Provider(exampleToken, useClass: Example),

          // [7] useValue with a literal (non-class)
          const Provider(exampleToken, useValue: 'Hello World'),

          // [8] useValue with a combination of literal + classes
          const Provider(exampleToken, useValue: const [
            const Duration(seconds: 5),
          ]),

          // [9] New ProviderUseClass
          const ProviderUseClass<Example, ExamplePrime>(),
        ];
      ''');
      $Example = testLib.getType('Example');
      $ExamplePrime = testLib.getType('ExamplePrime');
      $DependencyA = testLib.getType('DependencyA');
      $DependencyB = testLib.getType('DependencyB');
      $createExample = testLib.definingCompilationUnit.functions.first;
      providers = $Example.metadata.first.computeConstantValue().toListValue();
    });

    test('a type (implicit provider)', () {
      expect(
        reader.parseProvider(providers[0]),
        new UseClassProviderElement(
          new TypeTokenElement(urlOf($Example)),
          urlOf($Example),
          dependencies: new DependencyInvocation(
            $Example.unnamedConstructor,
            const [],
          ),
        ),
      );
    });

    test('a type (explicit provider)', () {
      expect(
        reader.parseProvider(providers[1]),
        new UseClassProviderElement(
          new TypeTokenElement(urlOf($Example)),
          urlOf($Example),
          dependencies: new DependencyInvocation(
            $Example.unnamedConstructor,
            const [],
          ),
        ),
      );
    });

    test('using useClass: ... to define the invocation', () {
      expect(
        reader.parseProvider(providers[2]),
        new UseClassProviderElement(
          new TypeTokenElement(urlOf($Example)),
          urlOf($ExamplePrime),
          dependencies: new DependencyInvocation(
            $ExamplePrime.unnamedConstructor,
            const [],
          ),
        ),
      );
    });

    test('using useFactory: ... to define the invocation', () {
      expect(
        reader.parseProvider(providers[3]),
        new UseFactoryProviderElement(
          new TypeTokenElement(urlOf($Example)),
          urlOf($createExample),
          dependencies: new DependencyInvocation(
            $createExample,
            [
              new DependencyElement(
                new TypeTokenElement(urlOf($DependencyA)),
              ),
            ],
          ),
        ),
      );
    });

    test('using useFactory: ... to define the invocation with deps: ...', () {
      expect(
        reader.parseProvider(providers[4]),
        new UseFactoryProviderElement(
          new TypeTokenElement(urlOf($Example)),
          urlOf($createExample),
          dependencies: new DependencyInvocation(
            $createExample,
            [
              new DependencyElement(
                new TypeTokenElement(urlOf($DependencyB)),
              ),
            ],
          ),
        ),
      );
    });

    test('using useValue: ... to define a constant invocation', () {
      final useValue = reader.parseProvider(
        providers[5],
      ) as UseValueProviderElement;
      expect(
        useValue.token,
        new TypeTokenElement(Uri.parse('dart:core#Duration')),
      );
      expect(useValue.useValue, const isInstanceOf<Revivable>());
      final revivable = useValue.useValue as Revivable;
      expect(revivable.source, Uri.parse('dart:core#Duration'));
      expect(revivable.accessor, '');
      expect(literalStringMap(revivable.namedArguments), {
        'seconds': 5,
      });
    });

    test('using useValue: ... to define a literal', () {
      final useValue = reader.parseProvider(
        providers[7],
      ) as UseValueProviderElement;
      expect(useValue.useValue, 'Hello World');
    });

    test('using useValue: ... to define a literal and constant invocation', () {
      final useValue = reader.parseProvider(
        providers[8],
      ) as UseValueProviderElement;
      expect(useValue.useValue, const isInstanceOf<List>());

      final useValueList = useValue.useValue as List<Object>;
      expect(useValueList, hasLength(1));

      expect(useValueList.first, const isInstanceOf<Revivable>());
      final revivable = useValueList.first as Revivable;
      expect(revivable.source, Uri.parse('dart:core#Duration'));
      expect(revivable.accessor, '');
      expect(literalStringMap(revivable.namedArguments), {
        'seconds': 5,
      });
    });

    test('using an OpaqueToken instead of a Type', () {
      expect(
        reader.parseProvider(providers[6]),
        new UseClassProviderElement(
          new OpaqueTokenElement('exampleToken'),
          urlOf($Example),
          dependencies: new DependencyInvocation(
            $Example.unnamedConstructor,
            const [],
          ),
        ),
      );
    });

    test('using the new "ProviderUseClass" type', () {
      expect(
        reader.parseProvider(providers[9]),
        new UseClassProviderElement(
          new TypeTokenElement(urlOf($Example)),
          urlOf($ExamplePrime),
          dependencies: new DependencyInvocation(
            $ExamplePrime.unnamedConstructor,
            const [],
          ),
        ),
      );
    });
  });
}
