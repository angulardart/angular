import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v2/context.dart';

import '../src/resolve.dart';

void main() {
  CompileContext.overrideForTesting();

  group('should generate injector with', () {
    final dartfmt = DartFormatter();
    EqualsDart.format = dartfmt.format;
    late InjectorEmitter emitter;
    late List<InjectorReader> injectors;

    setUp(() {
      emitter = InjectorEmitter();
    });

    setUpAll(() async {
      final library = await resolveLibrary(r'''
        // @dart=2.9
        @GenerateInjector([
          FactoryProvider(Foo, createFooDynamicDependency),
        ])
        InjectorFactory createInjectorDynamicDependency;

        class Foo {}

        Foo createFooDynamicDependency(dep) => Foo();
      ''');
      injectors = InjectorReader.findInjectors(library);
    });

    InjectorReader injectorNamed(String name) =>
        injectors.firstWhere((r) => r.field.name == name);

    test('a dependency with no type or token annotation', () {
      injectorNamed('createInjectorDynamicDependency').accept(emitter);
      expect(
        emitter.createClass(),
        equalsDart(r'''
          class _Injector$createInjectorDynamicDependency extends HierarchicalInjector implements Injector {
            _Injector$createInjectorDynamicDependency._(Injector parent) : super(parent);

            Object _field0;

            Object _getObject$0() => _field0 ??= createFooDynamicDependency(this.get(dynamic));
            Injector _getInjector$1() => this;
            @override
            Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
              if (identical(token, Foo)) {
                return _getObject$0();
              }
              if (identical(token, Injector)) {
                return _getInjector$1();
              }
              return orElse;
            }
          }
        '''),
      );
    });
  });

  group('exceptions', () {
    late InjectorEmitter emitter;
    late InjectorReader injector;

    setUp(() {
      emitter = InjectorEmitter();
    });

    setUpAll(() async {
      final library = await resolveLibrary(r'''
        // @dart=2.9
        @GenerateInjector([
          ValueProvider(Foo, Foo(Foo)),
        ])
        InjectorFactory injectorFactory;

        class Foo {
          const Foo(Type t);
        }
      ''');
      injector = InjectorReader.findInjectors(library).first;
    });

    test('should throw on a type in a ValueProvider', () {
      expect(() {
        try {
          injector.accept(emitter);
        } on BuildError catch (e) {
          expect(
              e.toString(),
              allOf([
                contains('Reviving Types is not supported'),
                contains('line 8, column 25 of')
              ]));
          rethrow;
        }
      }, throwsA(const TypeMatcher<BuildError>()));
    });
  });
}
