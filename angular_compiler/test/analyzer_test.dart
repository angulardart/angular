import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/src/analyzer.dart';
import 'package:test/test.dart';

import 'src/resolve.dart';

void main() {
  // These tests analyze whether our $Meta types are pointing to the right URLs.
  group('should analyze ', () {
    test('@Directive', () async {
      final aDirective = await resolveClass(r'''
      @Directive()
      class ADirective {}
    ''');
      expect($Directive.firstAnnotationOfExact(aDirective), isNotNull);
    });

    test('@Component', () async {
      final aComponent = await resolveClass(r'''
      @Component()
      class AComponent {}
    ''');
      expect($Component.firstAnnotationOfExact(aComponent), isNotNull);
    });

    test('@Pipe', () async {
      final aPipe = await resolveClass(r'''
      @Pipe('aPipe')
      class APipe {}
    ''');
      expect($Pipe.firstAnnotationOfExact(aPipe), isNotNull);
    });

    test('@Injectable', () async {
      final anInjectable = await resolveClass(r'''
      @Injectable()
      class AnInjectable {}
    ''');
      expect($Injectable.firstAnnotationOfExact(anInjectable), isNotNull);
    });

    test('@Attribute', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        AComponent(@Attribute('name') String name);
      }
    ''');
      final depParam = aComponent.constructors.first.parameters.first;
      expect($Attribute.firstAnnotationOfExact(depParam), isNotNull);
    });

    test('@Inject', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        AComponent(@Inject(#dep) List dep);
      }
    ''');
      final depParam = aComponent.constructors.first.parameters.first;
      expect($Inject.firstAnnotationOfExact(depParam), isNotNull);
    });

    test('@Optional', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        AComponent(@Optional() List dep);
      }
    ''');
      final depParam = aComponent.constructors.first.parameters.first;
      expect($Optional.firstAnnotationOfExact(depParam), isNotNull);
    });

    test('@Self', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        AComponent(@Self() List dep);
      }
    ''');
      final depParam = aComponent.constructors.first.parameters.first;
      expect($Self.firstAnnotationOfExact(depParam), isNotNull);
    });

    test('@SkipSelf', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        AComponent(@SkipSelf() List dep);
      }
    ''');
      final depParam = aComponent.constructors.first.parameters.first;
      expect($SkipSelf.firstAnnotationOfExact(depParam), isNotNull);
    });

    test('@Host', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        AComponent(@Host() List dep);
      }
    ''');
      final depParam = aComponent.constructors.first.parameters.first;
      expect($Host.firstAnnotationOfExact(depParam), isNotNull);
    });

    test('@ContentChildren', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @ContentChildren()
        List<AChild> children;
      }

      class AChild {}
    ''');
      final queryField = aComponent.fields.first;
      expect($ContentChildren.firstAnnotationOfExact(queryField), isNotNull);
    });

    test('@ContentChild', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @ContentChild()
        AChild child;
      }

      class AChild {}
    ''');
      final queryField = aComponent.fields.first;
      expect($ContentChild.firstAnnotationOfExact(queryField), isNotNull);
    });

    test('@ViewChildren', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @ViewChildren()
        List<AChild> children;
      }

      class AChild {}
    ''');
      final queryField = aComponent.fields.first;
      expect($ViewChildren.firstAnnotationOfExact(queryField), isNotNull);
    });

    test('@ViewChild', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @ViewChild()
        AChild children;
      }

      class AChild {}
    ''');
      final queryField = aComponent.fields.first;
      expect($ViewChild.firstAnnotationOfExact(queryField), isNotNull);
    });

    test('@Input', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @Input()
        String name;
      }
    ''');
      final inputField = aComponent.fields.first;
      expect($Input.firstAnnotationOfExact(inputField), isNotNull);
    });

    test('@Output', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @Output()
        Stream get event => null;
      }
    ''');
      final outputGetter = aComponent.accessors.first;
      expect($Output.firstAnnotationOfExact(outputGetter), isNotNull);
    });

    test('@HostBinding', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @HostBinding()
        String get name => 'name';
      }
    ''');
      final hostGetter = aComponent.accessors.first;
      expect($HostBinding.firstAnnotationOfExact(hostGetter), isNotNull);
    });

    test('@HostListener', () async {
      final aComponent = await resolveClass(r'''
      class AComponent {
        @HostListener('event')
        void onEvent() {}
      }
    ''');
      final hostMethod = aComponent.methods.first;
      expect($HostListener.firstAnnotationOfExact(hostMethod), isNotNull);
    });
  });

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
