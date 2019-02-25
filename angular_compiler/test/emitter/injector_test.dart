import 'package:angular_compiler/angular_compiler.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  final dartfmt = DartFormatter();
  EqualsDart.format = dartfmt.format;

  InjectorEmitter emitter;

  setUp(() {
    emitter = InjectorEmitter()..visitMeta('FooInjector', 'fooInjector');
  });

  test('createFactory should return a factory function', () {
    emitter.visitMeta('FooInjector', 'fooInjector');
    expect(
      Library((b) => b.body.add(emitter.createFactory())),
      equalsDart(r'''
        Injector fooInjector([Injector parent]) => FooInjector._(parent);
      '''),
    );
  });

  group('createClass should return a class', () {
    test('empty case', () {
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector {
          FooInjector._([Injector parent]) : super(parent);

          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            return orElse;
          }
        }
      '''),
      );
    });
  });

  group('createInjectSelfOptional', () {
    test('should support returning a ClassProvider', () {
      // provide(Foo, useClass: FooImpl)
      emitter.visitProvideClass(
        0,
        null,
        refer('Foo'),
        refer('FooImpl'),
        null,
        [
          refer('this.get').call([refer('Dep1')]),
          refer('this.get').call([refer('Dep2')]),
        ],
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector {
          FooInjector._([Injector parent]) : super(parent);

          FooImpl _field0;

          FooImpl _getFooImpl$0() => _field0 ??= FooImpl(this.get(Dep1), this.get(Dep2));
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return _getFooImpl$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support returning a ExistingProvider', () {
      // provide(FooPrime, useExisting: Foo)
      emitter.visitProvideExisting(
        0,
        null,
        refer('FooPrime'),
        refer('Foo'),
        refer('Foo'),
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector {
          FooInjector._([Injector parent]) : super(parent);

          Foo _getExisting$0() => this.get(Foo);
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, FooPrime)) {
              return _getExisting$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support returning a FactoryProvider', () {
      // provide(Foo, useFactory: createFoo)
      emitter.visitProvideFactory(
        0,
        null,
        refer('Foo'),
        refer('Foo'),
        refer('createFoo'),
        [
          refer('this.get').call([refer('Dep1')]),
          refer('this.get').call([refer('Dep2')]),
        ],
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector {
          FooInjector._([Injector parent]) : super(parent);

          Foo _field0;

          Foo _getFoo$0() => _field0 ??= createFoo(this.get(Dep1), this.get(Dep2));
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return _getFoo$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support returning a ValueProvider', () {
      // provide(Foo, useValue: const Foo())
      emitter.visitProvideValue(
        0,
        null,
        refer('Foo'),
        refer('Foo'),
        refer('Foo').constInstance([]),
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector {
          FooInjector._([Injector parent]) : super(parent);

          Foo _getFoo$0() => const Foo();
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return _getFoo$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support a MultiToken', () {
      // provide(someToken, useValue: 1, multi: true)
      // provide(someToken, useValue: 2, multi: true)
      final someToken = OpaqueTokenElement(
        'someToken',
        isMultiToken: true,
        classUrl: TypeLink(
          'MultiToken',
          ''
              'package:angular'
              '/src/core/di/opaque_token.dart',
        ),
      );
      emitter.visitProvideValue(
        0,
        someToken,
        refer('someToken'),
        refer('int'),
        literal(1),
        true,
      );
      emitter.visitProvideValue(
        1,
        someToken,
        refer('someToken'),
        refer('int'),
        literal(2),
        true,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector {
          FooInjector._([Injector parent]) : super(parent);

          int _getint$0() => 1;
          int _getint$1() => 2;
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, someToken)) {
              return [_getint$0(), _getint$1()];
            }
            return orElse;
          }
        }
        '''),
      );
    });
  });
}
