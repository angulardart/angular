import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v2/context.dart';

import '../../src/resolve.dart';

void main() {
  CompileContext.overrideForTesting();

  final refersToOpaqueToken = TypeLink(
    'OpaqueToken',
    'asset:angular/lib/src/meta/di_tokens.dart',
    generics: [TypeLink.$object],
  );

  group('should parse provider from', () {
    late List<DartObject> providers;
    const reader = ProviderReader();

    late ClassElement $Example;
    late ClassElement $ExamplePrime;
    late ClassElement $DependencyA;
    late ClassElement $DependencyB;
    late FunctionElement $createExample;
    late MethodElement $Example_create;

    setUpAll(() async {
      final testLib = await resolveLibrary(r'''
        @exampleModule
        @newModuleA
        @newModuleB
        class Example {
          static Example create(DependencyA a) => Example();
        }

        class ExamplePrime extends Example {}

        class DependencyA {}
        class DependencyB {}

        Example createExample(DependencyA a) => new ExamplePrime();

        const exampleToken = const OpaqueToken('exampleToken');
        const usPresidents = const MultiToken<String>('usPresidents');
        const anotherToken = const OpaqueToken('anotherToken');

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

          // [9] Implicit multi: true.
          const Provider(usPresidents, useValue: 'George Washington'),

          // [10] With a type (explicit).
          const Provider<String>(anotherToken, useValue: 'Hello World'),

          // [11] useFactory with static method
          const Provider(Example, useFactory: Example.create),

          // [12] useFactory with static method and explicit deps
          const Provider(
            Example,
            useFactory: Example.create,
            deps: [DependencyB]
          ),
        ];
      ''');
      $Example = testLib.getType('Example')!;
      $ExamplePrime = testLib.getType('ExamplePrime')!;
      $DependencyA = testLib.getType('DependencyA')!;
      $DependencyB = testLib.getType('DependencyB')!;
      $createExample = testLib.definingCompilationUnit.functions.first;
      $Example_create = $Example.getMethod('create')!;
      providers =
          $Example.metadata.first.computeConstantValue()!.toListValue()!;
    });

    test('a type (implicit provider)', () {
      expect(
        reader.parseProvider(providers[0]),
        UseClassProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          linkTypeOf($Example.thisType),
          dependencies: DependencyInvocation(
            $Example.unnamedConstructor!,
            const [],
          ),
        ),
      );
    });

    test('a type (explicit provider)', () {
      expect(
        reader.parseProvider(providers[1]),
        UseClassProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          linkTypeOf($Example.thisType),
          dependencies: DependencyInvocation(
            $Example.unnamedConstructor!,
            const [],
          ),
        ),
      );
    });

    test('using useClass: ... to define the invocation', () {
      expect(
        reader.parseProvider(providers[2]),
        UseClassProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          linkTypeOf($ExamplePrime.thisType),
          dependencies: DependencyInvocation(
            $ExamplePrime.unnamedConstructor!,
            const [],
          ),
        ),
      );
    });

    test('using useFactory: ... to define the invocation', () {
      expect(
        reader.parseProvider(providers[3]),
        UseFactoryProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          urlOf($createExample),
          dependencies: DependencyInvocation(
            $createExample,
            [
              DependencyElement(
                TypeTokenElement(linkTypeOf($DependencyA.thisType)),
              ),
            ],
          ),
        ),
      );
    });

    test('using useFactory: ... to define the invocation with deps: ...', () {
      expect(
        reader.parseProvider(providers[4]),
        UseFactoryProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          urlOf($createExample),
          dependencies: DependencyInvocation(
            $createExample,
            [
              DependencyElement(
                TypeTokenElement(linkTypeOf($DependencyB.thisType)),
              ),
            ],
          ),
        ),
      );
    });

    test('using useFactory: ... to define the invocation of static method', () {
      expect(
        reader.parseProvider(providers[11]),
        UseFactoryProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          urlOf($Example_create),
          dependencies: DependencyInvocation(
            $Example_create,
            [
              DependencyElement(
                TypeTokenElement(linkTypeOf($DependencyA.thisType)),
              ),
            ],
          ),
        ),
      );
    });

    test(
        'using useFactory: ... to define the invocation of static method '
        'with deps: ...', () {
      expect(
        reader.parseProvider(providers[12]),
        UseFactoryProviderElement(
          TypeTokenElement(linkTypeOf($Example.thisType)),
          null,
          urlOf($Example_create),
          dependencies: DependencyInvocation(
            $Example_create,
            [
              DependencyElement(
                TypeTokenElement(linkTypeOf($DependencyB.thisType)),
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
        TypeTokenElement(const TypeLink('Duration', 'dart:core')),
      );
      expect(useValue.useValue!.type!.name, 'Duration');
    });

    test('using useValue: ... to define a literal', () {
      final useValue = reader.parseProvider(
        providers[7],
      ) as UseValueProviderElement;
      expect(useValue.useValue!.toStringValue(), 'Hello World');
    });

    test('using useValue: ... to define a literal and constant invocation', () {
      final useValue = reader.parseProvider(
        providers[8],
      ) as UseValueProviderElement;
      expect(useValue.useValue!.toListValue(), isNotEmpty);
    });

    test('using an OpaqueToken instead of a Type', () {
      expect(
        reader.parseProvider(providers[6]),
        UseClassProviderElement(
          OpaqueTokenElement(
            'exampleToken',
            isMultiToken: false,
            classUrl: refersToOpaqueToken,
          ),
          null,
          linkTypeOf($Example.thisType),
          dependencies: DependencyInvocation(
            $Example.unnamedConstructor!,
            const [],
          ),
        ),
      );
    });

    test('using a MultiToken instead of a Type', () {
      final value = reader.parseProvider(providers[9]);
      expect(value, TypeMatcher<UseValueProviderElement>());
      expect((value.token as OpaqueTokenElement).isMultiToken, isTrue);
      expect((value.token as OpaqueTokenElement).identifier, 'usPresidents');
      expect(value.isMulti, isTrue);
    });

    test('using an explicit Provider type <T>', () {
      final value = reader.parseProvider(providers[10]);
      expect(value, TypeMatcher<UseValueProviderElement>());
      expect(value.providerType, TypeLink('String', 'dart:core'));
    });
  });
}
