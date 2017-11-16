@Tags(const ['codegen'])
@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'directive_test.template.dart' as ng_generated;

/// Verifies whether injection through directives/components is correct.
void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should use the proper provider bindings in a hierarchy', () async {
    final fixture = await new NgTestBed<TestParent>().create();
    B serviceB;
    A serviceA;
    await fixture.update((comp) {
      serviceB = comp.parent.child1.b;
      serviceA = comp.parent.child1.child2.a;
    });
    expect(
      serviceB.c.debugMessage,
      'newC',
      reason: '"B" should have been resolved with the newer "C" binding',
    );
    expect(
      serviceA.b.c.debugMessage,
      'oldC',
      reason: '"A" should have been resolved with the older "C" binding',
    );
  });

  test('should use user-default value on ElementInjector.get', () async {
    final fixture = await new NgTestBed<UsingElementInjector>().create();
    await fixture.update((comp) {
      final foo = comp.injector.get(#foo, 'someValue');
      expect(foo, 'someValue');
    });
  });

  test('should support multi: true without reified generics', () async {
    final fixture = await new NgTestBed<ErasedMultiGenerics>().create();
    expect(
      fixture.assertOnlyInstance.usPresidents,
      const isInstanceOf<List>(),
    );
    expect(fixture.text, '[George, Abraham]');
  });

  test('should reify a MultiProvider<T> in strong-mode runtimes', () async {
    final fixture = await new NgTestBed<ReifiedMultiGenerics>().create();
    expect(
      fixture.assertOnlyInstance.usPresidents,
      const isInstanceOf<List<String>>(),
    );
    expect(fixture.text, '[George, Abraham]');
  });

  group('should support optional values', () {
    NgTestBed<UsingInjectAndOptional> testBed;

    setUp(() => testBed = new NgTestBed<UsingInjectAndOptional>());

    test('when provided', () async {
      testBed = testBed.addProviders([
        provide(urlToken, useValue: 'https://google.com'),
      ]);
      final fixture = await testBed.create();
      expect(
        fixture.assertOnlyInstance.service.urlFromToken,
        'https://google.com',
      );
    });

    test('when omitted', () async {
      final fixture = await testBed.create();
      expect(
        fixture.assertOnlyInstance.service.urlFromToken,
        isNull,
      );
    });
  });
}

@Component(
  selector: 'test-parent',
  template: '<parent></parent>',
  directives: const [
    CompParent,
  ],
)
class TestParent {
  @ViewChild(CompParent)
  CompParent parent;
}

@Component(
  selector: 'parent',
  template: '<child-1></child-1>',
  directives: const [
    CompChild1,
  ],
  providers: const [
    A,
    B,
    const Provider(C, useValue: const C('oldC')),
  ],
)
class CompParent {
  @ViewChild(CompChild1)
  CompChild1 child1;
}

@Component(
  selector: 'child-1',
  template: '<child-2></child-2>',
  directives: const [
    CompChild2,
  ],
  providers: const [
    B,
    const Provider(C, useValue: const C('newC')),
  ],
)
class CompChild1 {
  final B b;

  CompChild1(this.b);

  @ViewChild(CompChild2)
  CompChild2 child2;
}

@Component(
  selector: 'child-2',
  template: '',
)
class CompChild2 {
  final A a;

  CompChild2(this.a);
}

@Injectable()
class A {
  final B b;
  A(this.b);
}

@Injectable()
class B {
  final C c;
  B(this.c);
}

@Injectable()
class C {
  final String debugMessage;

  const C(this.debugMessage);

  @override
  String toString() => 'C: $debugMessage';
}

@Component(
  selector: 'using-element-injector',
  template: '',
)
class UsingElementInjector {
  final Injector injector;

  UsingElementInjector(this.injector);
}

@Component(
  selector: 'using-inject-and-optional',
  template: '',
  providers: const [
    const Provider(ExampleServiceOptionals, useClass: ExampleServiceOptionals),
  ],
)
class UsingInjectAndOptional {
  final ExampleServiceOptionals service;

  UsingInjectAndOptional(this.service);
}

const urlToken = const OpaqueToken('urlToken');

class ExampleServiceOptionals {
  final String urlFromToken;

  ExampleServiceOptionals(
    @Inject(urlToken) @Optional() this.urlFromToken,
  );
}

const usPresidentsToken = const OpaqueToken<String>('usPresidents');

@Component(
  selector: 'reified-multi-generics',
  providers: const [
    const Provider(usPresidentsToken, useValue: 'George', multi: true),
    const Provider(usPresidentsToken, useValue: 'Abraham', multi: true),
  ],
  template: "{{usPresidents}}",
)
class ErasedMultiGenerics {
  final List<dynamic> usPresidents;

  ErasedMultiGenerics(@Inject(usPresidentsToken) this.usPresidents);
}

@Component(
  selector: 'reified-multi-generics',
  providers: const [
    const Provider<String>(usPresidentsToken, useValue: 'George', multi: true),
    const Provider<String>(usPresidentsToken, useValue: 'Abraham', multi: true),
  ],
  template: "{{usPresidents}}",
)
class ReifiedMultiGenerics {
  final List<String> usPresidents;

  ReifiedMultiGenerics(@Inject(usPresidentsToken) this.usPresidents);
}
