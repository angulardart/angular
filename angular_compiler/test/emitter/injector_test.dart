import 'package:angular_compiler/angular_compiler.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

void main() {
  InjectorEmitter emitter;

  setUp(() => emitter = new InjectorEmitter());

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
      emitter.visitMeta('FooInjector', 'fooInjector');
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

    test('with a provider', () {
      emitter.visitMeta('FooInjector', 'fooInjector');
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

          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return _field0 ??= new FooImpl(inject(Dep1), inject(Dep2));
            }
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
        emitter.createInjectSelfOptional(),
        equalsDart(r'''
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return _field0 ??= new FooImpl(inject(Dep1), inject(Dep2));
            }
            return orElse;
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
        false,
      );
      expect(
        emitter.createInjectSelfOptional(),
        equalsDart(r'''
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, FooPrime)) {
              return inject(Foo);
            }
            return orElse;
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
        emitter.createInjectSelfOptional(),
        equalsDart(r'''
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return _field0 ??= createFoo(inject(Dep1), inject(Dep2));
            }
            return orElse;
          }
        '''),
      );
    });

    test('should support returning a ValueProvider', () {
      // provide(Foo, useValue: const Foo())
      emitter.visitProvideValue(
        0,
        refer('Foo'),
        refer('Foo').constInstance([]),
        false,
      );
      expect(
        emitter.createInjectSelfOptional(),
        equalsDart(r'''
          @override
          Object injectFromSelfOptional(Object token, [Object orElse = throwIfNotFound]) {
            if (identical(token, Foo)) {
              return const Foo();
            }
            return orElse;
          }
        '''),
      );
    });
  });
}
