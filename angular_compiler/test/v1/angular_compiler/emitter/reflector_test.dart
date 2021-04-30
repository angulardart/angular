import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mockito/mockito.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v2/context.dart';

import '../src/resolve.dart';

void main() {
  CompileContext.overrideForTesting();

  final dartfmt = DartFormatter().format;
  final angular = 'package:angular';
  final libReflection = '$angular/src/core/reflection/reflection.dart';

  // We don't have a true "source" library to use in these tests. Its OK.
  //
  // (Normally this is used to determine relative import paths, etc)
  // TODO(b/186587400): Refactor the mock object now owned by AngularDart team.
  final nullLibrary = LibraryReader(MockLibraryElement());

  test('should support a no-op', () {
    final output = ReflectableOutput();
    final emitter = ReflectableEmitter(output, nullLibrary);
    expect(emitter.emitImports(), isEmpty);
    expect(
      emitter.emitInitReflector(),
      '// No initReflector() linking required.\nvoid initReflector(){}',
    );
  });

  test('should support linking', () {
    final output = ReflectableOutput(
      urlsNeedingInitReflector: ['foo.template.dart'],
    );
    final emitter = ReflectableEmitter(output, nullLibrary);
    expect(
      dartfmt(emitter.emitImports()),
      dartfmt(r'''
        import 'foo.template.dart' as _ref0;
      '''),
    );
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;

          _ref0.initReflector();
        }
      '''),
    );
  });

  test('should register constructors for injectable services', () async {
    final reflector = ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      const someToken = OpaqueToken('someToken');
      class A {}
      class B {}
      class C {}

      @Injectable()
      class ExampleServiceNoDeps {}

      @Injectable()
      class ExampleServiceWithDeps {
        ExampleServiceWithDeps(A a, B b, C c);
      }

      @Injectable()
      class ExampleServiceWithNamedConstructor {
        ExampleServiceWithNamedConstructor.namedConstructor(A a, B b, C c);
      }

      @Injectable()
      class ExampleServiceWithDynamicDeps {
        ExampleServiceWithDynamicDeps(@Inject(someToken) a);
      }

      @Injectable()
      class ExampleServiceWithDynamicDeps2 {
        ExampleServiceWithDynamicDeps2(@someToken a);
      }
    '''));
    final emitter = ReflectableEmitter(
      output,
      nullLibrary,
      reflectorSource: libReflection,
    );
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;

          _ngRef.registerFactory(
            ExampleServiceNoDeps,
            () => ExampleServiceNoDeps()
          );
          _ngRef.registerFactory(
            ExampleServiceWithDeps,
            (A p0, B p1, C p2) => ExampleServiceWithDeps(p0, p1, p2)
          );
          _ngRef.registerDependencies(
            ExampleServiceWithDeps,
            const [
              [A],
              [B],
              [C]
            ]
          );
          _ngRef.registerFactory(
            ExampleServiceWithNamedConstructor,
            (A p0, B p1, C p2) => ExampleServiceWithNamedConstructor.namedConstructor(p0, p1, p2)
          );
          _ngRef.registerDependencies(
            ExampleServiceWithNamedConstructor,
            const [
              [A],
              [B],
              [C]
            ]
          );
          _ngRef.registerFactory(
            ExampleServiceWithDynamicDeps,
            (dynamic p0) => ExampleServiceWithDynamicDeps(p0)
          );
          _ngRef.registerDependencies(
            ExampleServiceWithDynamicDeps,
            const [
              [
                _ngRef.Inject(OpaqueToken<Object>('someToken'))
              ]
            ]
          );
          _ngRef.registerFactory(
            ExampleServiceWithDynamicDeps2,
            (dynamic p0) => ExampleServiceWithDynamicDeps2(p0)
          );
          _ngRef.registerDependencies(
            ExampleServiceWithDynamicDeps2,
            const [
              [
                _ngRef.Inject(OpaqueToken<Object>('someToken'))
              ]
            ]
          );
        }
      '''),
    );
  });

  test('should register dependencies for injectable top-level function',
      () async {
    final reflector = ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      const someToken = OpaqueToken('someToken');
      class SomeDependency {};
      class A {}
      class B {}
      class C {}
      class D {}
      class E {}
      class F {}
      class G {}

      int nonInjectable(SomeDependency s);

      @Injectable()
      A createA();

      @Injectable()
      B createB(SomeDependency s);

      @Injectable()
      C createC(@Inject(someToken) s);

      @Injectable()
      D createD(@someToken s);

      @Injectable()
      E createE(@Optional() SomeDependency? s);

      @Injectable()
      F createF(@SkipSelf() SomeDependency s);

      @Injectable()
      G createG(@Host() SomeDependency s);
    '''));
    final emitter = ReflectableEmitter(
      output,
      nullLibrary,
      reflectorSource: libReflection,
    );
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;

          _ngRef.registerDependencies(createB, const [
            [SomeDependency]
          ]);
          _ngRef.registerDependencies(createC, const [
            [_ngRef.Inject(OpaqueToken<Object>('someToken'))]
          ]);
          _ngRef.registerDependencies(createD, const [
            [_ngRef.Inject(OpaqueToken<Object>('someToken'))]
          ]);
          _ngRef.registerDependencies(createE, const [
            [SomeDependency, _ngRef.Optional()]
          ]);
          _ngRef.registerDependencies(createF, const [
            [SomeDependency, _ngRef.SkipSelf()]
          ]);
          _ngRef.registerDependencies(createG, const [
            [SomeDependency, _ngRef.Host()]
          ]);
        }
      '''),
    );
  });

  test('should register dependencies for injectable static methods', () async {
    final reflector = ReflectableReader.noLinking();
    final output = await reflector.resolve(await resolveLibrary(r'''
      const someToken = OpaqueToken('someToken');
      class SomeDependency {};
      class A {}
      class B {}
      class C {}
      class D {}
      class E {}
      class F {}
      class G {}

      class Creator {
        static int nonInjectable(SomeDependency s);

        @Injectable()
        static A createA();

        @Injectable()
        static B createB(SomeDependency s);

        @Injectable()
        static C createC(@Inject(someToken) s);

        @Injectable()
        static D createD(@someToken s);

        @Injectable()
        static E createE(@Optional() SomeDependency? s);

        @Injectable()
        static F createF(@SkipSelf() SomeDependency s);

        @Injectable()
        static G createG(@Host() SomeDependency s);
      }
    '''));
    final emitter = ReflectableEmitter(
      output,
      nullLibrary,
      reflectorSource: libReflection,
    );
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;

          _ngRef.registerDependencies(Creator.createB, const [
            [SomeDependency]
          ]);
          _ngRef.registerDependencies(Creator.createC, const [
            [_ngRef.Inject(OpaqueToken<Object>('someToken'))]
          ]);
          _ngRef.registerDependencies(Creator.createD, const [
            [_ngRef.Inject(OpaqueToken<Object>('someToken'))]
          ]);
          _ngRef.registerDependencies(Creator.createE, const [
            [SomeDependency, _ngRef.Optional()]
          ]);
          _ngRef.registerDependencies(Creator.createF, const [
            [SomeDependency, _ngRef.SkipSelf()]
          ]);
          _ngRef.registerDependencies(Creator.createG, const [
            [SomeDependency, _ngRef.Host()]
          ]);
        }
      '''),
    );
  });

  test('should handle relative paths in a test directory', () async {
    // This a silly, but effective way, to get a LibraryElement.
    final pkgATest = await resolveSources(
      {
        'a|test/a_test.dart': '''
          library a_test;

          import '$angular/angular.dart';

          import 'a_data.dart';

          @Injectable()
          class InjectsB {
            InjectsB(B b);
          }
        ''',
        'a|test/a_data.dart': r'''
          library a_data;

          class B {}
        ''',
      },
      (r) => r.libraryFor(AssetId('a', 'test/a_test.dart')),
      packageConfig: await packageConfigFuture,
    );
    final library = LibraryReader(pkgATest);
    final reflector = ReflectableReader.noLinking();
    final output = await reflector.resolve(pkgATest);
    final allocator = Allocator.simplePrefixing();
    final emitter = ReflectableEmitter(
      output,
      library,
      allocator: allocator,
      reflectorSource: libReflection,
    );
    expect(
      dartfmt(emitter.emitImports()),
      dartfmt('''
        import 'a_data.dart' as _i1;
        import '$libReflection' as _ngRef;
      '''),
    );
    expect(
      dartfmt(emitter.emitInitReflector()),
      dartfmt(r'''
        var _visited = false;
        void initReflector() {
          if (_visited) {
            return;
          }
          _visited = true;

          _ngRef.registerFactory(InjectsB, (_i1.B p0) => InjectsB(p0));
          _ngRef.registerDependencies(InjectsB, const [
            [
              _i1.B
            ]
          ]);
        }
      '''),
    );
  });

  group('should handle generic type parameters where', () {
    Future<String> initReflectorOf(String source) async {
      final library = LibraryReader(await resolveLibrary(source));
      final reflector = ReflectableReader.noLinking();
      final output = await reflector.resolve(library.element);
      final emitter = ReflectableEmitter(output, library);
      return emitter.emitInitReflector();
    }

    test('there is no bound type (default to dynamic)', () async {
      final source = r'''
        class GenericType<T> {}

        @Injectable()
        class InjectsGeneric {
          InjectsGeneric(GenericType a);
        }
      ''';
      expect(
        dartfmt(await initReflectorOf(source)),
        dartfmt(r'''
          var _visited = false;
          void initReflector() {
            if (_visited) {
              return;
            }
            _visited = true;

            _ngRef.registerFactory(InjectsGeneric, (GenericType<dynamic> p0) => InjectsGeneric(p0));
            _ngRef.registerDependencies(InjectsGeneric, const [
              [
                GenericType
              ]
            ]);
          }
        '''),
      );
    });

    test('the bound type is private (default to dynamic)', () async {
      final source = r'''
        class GenericType<T> {}
        class _PrivateType {}

        @Injectable()
        class InjectsGeneric {
          InjectsGeneric(GenericType<_PrivateType> a);
        }
      ''';
      expect(
        dartfmt(await initReflectorOf(source)),
        dartfmt(r'''
          var _visited = false;
          void initReflector() {
            if (_visited) {
              return;
            }
            _visited = true;

            _ngRef.registerFactory(InjectsGeneric, (GenericType<dynamic> p0) => InjectsGeneric(p0));
            _ngRef.registerDependencies(InjectsGeneric, const [
              [
                GenericType
              ]
            ]);
          }
        '''),
      );
    });

    test('the bound type is non-dynamic', () async {
      final source = r'''
        class GenericType<T> {}

        @Injectable()
        class InjectsGeneric {
          InjectsGeneric(GenericType<String> a);
        }
      ''';
      expect(
        dartfmt(await initReflectorOf(source)),
        dartfmt(r'''
          var _visited = false;
          void initReflector() {
            if (_visited) {
              return;
            }
            _visited = true;

            _ngRef.registerFactory(InjectsGeneric, (GenericType<String> p0) => InjectsGeneric(p0));
            _ngRef.registerDependencies(InjectsGeneric, const [
              [
                GenericType
              ]
            ]);
          }
        '''),
      );
    });

    test('the bound type extends another a non-dynamic type', () async {
      final source = r'''
        class GenericType<T extends Comparable<T>> {}

        @Injectable()
        class InjectsGeneric {
          InjectsGeneric(GenericType a);
        }
      ''';
      expect(
        dartfmt(await initReflectorOf(source)),
        dartfmt(r'''
          var _visited = false;
          void initReflector() {
            if (_visited) {
              return;
            }
            _visited = true;

            _ngRef.registerFactory(InjectsGeneric, (GenericType<Comparable<dynamic>> p0) => InjectsGeneric(p0));
            _ngRef.registerDependencies(InjectsGeneric, const [
              [
                GenericType
              ]
            ]);
          }
        '''),
      );
    });

    test('the bound type extends another bound type', () async {
      final source = r'''
        class GenericType<T> {}

        @Injectable()
        class InjectsGeneric<T extends String> {
          InjectsGeneric(GenericType<T> a);
        }
      ''';
      expect(
        dartfmt(await initReflectorOf(source)),
        dartfmt(r'''
          var _visited = false;
          void initReflector() {
            if (_visited) {
              return;
            }
            _visited = true;

            _ngRef.registerFactory(InjectsGeneric, (GenericType<String> p0) => InjectsGeneric(p0));
            _ngRef.registerDependencies(InjectsGeneric, const [
              [
                GenericType
              ]
            ]);
          }
        '''),
      );
    });

    test('the bound type extends another bound on the same class', () async {
      final source = r'''
        class GenericType<E extends Comparable<E>, T extends E> {}

        @Injectable()
        class InjectsGeneric {
          InjectsGeneric(GenericType a);
        }
      ''';
      expect(
        dartfmt(await initReflectorOf(source)),
        dartfmt(r'''
          var _visited = false;
          void initReflector() {
            if (_visited) {
              return;
            }
            _visited = true;

            _ngRef.registerFactory(InjectsGeneric, (GenericType<Comparable<dynamic>, Comparable<dynamic>> p0) => InjectsGeneric(p0));
            _ngRef.registerDependencies(InjectsGeneric, const [
              [
                GenericType
              ]
            ]);
          }
        '''),
      );
    });
  });
}

class MockLibraryElement extends Mock implements LibraryElement {}
