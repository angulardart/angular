import 'package:angular_compiler/angular_compiler.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  final dartfmt = new DartFormatter();
  EqualsDart.format = dartfmt.format;

  InjectorEmitter emitter;

  setUp(() {
    emitter = new InjectorEmitter()..visitMeta('FooInjector', 'fooInjector');
  });

  test('createFactory should return a factory function', () {
    emitter.visitMeta('FooInjector', 'fooInjector');
    expect(
      new Library((b) => b.body.add(emitter.createFactory())),
      equalsDart(r'''
        Injector fooInjector([Injector parent]) => new FooInjector._(parent);
      '''),
    );
  });

  group('createClass should return a class', () {
    test('empty case', () {
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends GeneratedInjector {
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
        refer('Foo'),
        refer('FooImpl'),
        null,
        [
          refer('inject').call([refer('Dep1')]),
          refer('inject').call([refer('Dep2')]),
        ],
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends GeneratedInjector {
          FooInjector._([Injector parent]) : super(parent);

          FooImpl _field0;

          FooImpl _getFooImpl$0() => _field0 ??= new FooImpl(inject(Dep1), inject(Dep2));
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
        refer('FooPrime'),
        refer('Foo'),
        refer('Foo'),
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends GeneratedInjector {
          FooInjector._([Injector parent]) : super(parent);

          Foo _getExisting$0() => inject(Foo);
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
        refer('Foo'),
        refer('Foo'),
        refer('createFoo'),
        [
          refer('inject').call([refer('Dep1')]),
          refer('inject').call([refer('Dep2')]),
        ],
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends GeneratedInjector {
          FooInjector._([Injector parent]) : super(parent);

          Foo _field0;

          Foo _getFoo$0() => _field0 ??= createFoo(inject(Dep1), inject(Dep2));
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
        refer('Foo'),
        refer('Foo'),
        refer('Foo').constInstance([]),
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends GeneratedInjector {
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
  });
}
