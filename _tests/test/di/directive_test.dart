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

  test('should reify a typed OpaqueToken<T>', () async {
    final fixture = await new NgTestBed<ReifiedMultiGenerics>().create();
    expect(
      fixture.assertOnlyInstance.usPresidents,
      const isInstanceOf<List<String>>(),
    );
    expect(fixture.text, '[George, Abraham]');
  });

  test('should reify a typed OpaqueToken<T> for a directive', () async {
    final fixture = await new NgTestBed<UsesTypedTokensComponent>().create();
    expect(
      fixture.assertOnlyInstance.directive.arbitrary,
      const isInstanceOf<List<Arbitrary>>(),
    );
  });

  test('should support typed tokens that are inferred', () async {
    final fixture = await new NgTestBed<SupportsInferredProviders>().create();
    expect(
      fixture.assertOnlyInstance.arbitrary,
      const isInstanceOf<List<Arbitrary>>(),
    );
  });

  test('should support MultiToken instead of multi: true', () async {
    final fixture = await new NgTestBed<SupportsMultiToken>().create();
    expect(
      fixture.assertOnlyInstance.values,
      const isInstanceOf<List<String>>(),
    );
  });

  test('should not consider Opaque/MultiToken the same token', () async {
    final fixture = await new NgTestBed<NoClashTokens>().create();
    expect(fixture.assertOnlyInstance.fooTokenFromOpaque, hasLength(1));
    expect(fixture.assertOnlyInstance.fooTokenFromMulti, hasLength(1));
  });

  test('should not consider tokens with different types the same', () async {
    final fixture = await new NgTestBed<SupportsTypedToken>().create();
    final value1 = fixture.assertOnlyInstance.injector.get(barTypedToken1);
    expect(value1, 1);
    final value2 = fixture.assertOnlyInstance.injector.get(barTypedToken2);
    expect(value2, 2);
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

  test('should treat tokens with different names as different', () async {
    final fixture = await new NgTestBed<ProperTokenIdentity>().create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(aDynamicTokenNamedA), 'A');
    expect(injector.get(aDynamicTokenNamedB), 'B');
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
    const Provider<String>(
      usPresidentsToken,
      useValue: 'George',
      multi: true,
    ),
    const Provider<String>(
      usPresidentsToken,
      useValue: 'Abraham',
      multi: true,
    ),
  ],
  template: "{{usPresidents}}",
)
class ReifiedMultiGenerics {
  final List<String> usPresidents;

  ReifiedMultiGenerics(@Inject(usPresidentsToken) this.usPresidents);
}

class Arbitrary {
  final int value;

  const Arbitrary(this.value);
}

const arbitraryToken = const OpaqueToken<Arbitrary>('arbitrary');

@Component(
  selector: 'uses-typed-tokens',
  directives: const [UsesTypedTokensDirective],
  providers: const [
    const Provider<Arbitrary>(
      arbitraryToken,
      useValue: const Arbitrary(1),
      multi: true,
    ),
    const Provider<Arbitrary>(
      arbitraryToken,
      useValue: const Arbitrary(2),
      multi: true,
    ),
  ],
  template: r'<button arbitrary></button>',
)
class UsesTypedTokensComponent {
  @ViewChild(UsesTypedTokensDirective)
  UsesTypedTokensDirective directive;
}

@Directive(
  selector: '[arbitrary]',
)
class UsesTypedTokensDirective {
  final List<Arbitrary> arbitrary;

  UsesTypedTokensDirective(@Inject(arbitraryToken) this.arbitrary);
}

@Component(
  selector: 'supports-inferred-providers',
  providers: const [
    const ValueProvider.forToken(
      arbitraryToken,
      const Arbitrary(1),
      multi: true,
    ),
  ],
  template: '',
)
class SupportsInferredProviders {
  final List<Arbitrary> arbitrary;

  SupportsInferredProviders(@Inject(arbitraryToken) this.arbitrary);
}

const usPresidentsMulti = const MultiToken<String>('usPresidents');

@Component(
  selector: 'supports-multi-token',
  providers: const [
    const ValueProvider.forToken(usPresidentsMulti, 'George Washington'),
    const ValueProvider.forToken(usPresidentsMulti, 'Abraham Lincoln'),
  ],
  template: '',
)
class SupportsMultiToken {
  final List<String> values;

  SupportsMultiToken(@Inject(usPresidentsMulti) this.values);
}

const fooOpaqueToken = const OpaqueToken<String>('fooToken');
const fooMultiToken = const MultiToken<String>('fooToken');

@Component(
  selector: 'no-clash-tokens',
  providers: const [
    const ValueProvider.forToken(fooOpaqueToken, 'Hello', multi: true),
    const ValueProvider.forToken(fooMultiToken, 'World'),
  ],
  template: '',
)
class NoClashTokens {
  final List<String> fooTokenFromOpaque;
  final List<String> fooTokenFromMulti;

  NoClashTokens(
    @Inject(fooOpaqueToken) this.fooTokenFromOpaque,
    @Inject(fooMultiToken) this.fooTokenFromMulti,
  );
}

const barTypedToken1 = const OpaqueToken<dynamic>('barTypedToken');
const barTypedToken2 = const OpaqueToken<bool>('barTypedToken');

@Component(
  selector: 'supports-typed-token',
  providers: const [
    const ValueProvider.forToken(barTypedToken1, 1),
    const ValueProvider.forToken(barTypedToken2, 2),
  ],
  template: '',
)
class SupportsTypedToken {
  final Injector injector;

  SupportsTypedToken(this.injector);
}

const aDynamicTokenNamedA = const OpaqueToken('A');
const aDynamicTokenNamedB = const OpaqueToken('B');

@Component(
  selector: 'proper-token-identity',
  providers: const [
    const Provider(aDynamicTokenNamedA, useValue: 'A'),
    const Provider(aDynamicTokenNamedB, useValue: 'B'),
  ],
  template: '',
)
class ProperTokenIdentity {
  final Injector injector;

  ProperTokenIdentity(this.injector);
}
