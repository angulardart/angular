import 'package:angular_compiler/angular_compiler.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  group('should generate injector with', () {
    final dartfmt = DartFormatter();
    EqualsDart.format = dartfmt.format;
    InjectorEmitter emitter;
    List<InjectorReader> injectors;

    setUp(() {
      emitter = InjectorEmitter();
    });

    setUpAll(() async {
      final library = await resolveLibrary(r'''
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
          class _Injector$createInjectorDynamicDependency extends HierarchicalInjector {
            _Injector$createInjectorDynamicDependency._([Injector parent]) : super(parent);

            dynamic _field0;

            dynamic _getdynamic$0() => _field0 ??= createFooDynamicDependency(this.get(dynamic));
            Injector _getInjector$1() => this;
            @override
            Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
              if (identical(token, Foo)) {
                return _getdynamic$0();
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
}
