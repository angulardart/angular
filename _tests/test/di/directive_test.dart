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
    final fixture = await NgTestBed<TestParent>().create();
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

  test('should consider Provider(T) as Provider(T, useClass: T)', () async {
    final fixture = await NgTestBed<SupportsImplicitClass>().create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(
      injector.get(ExampleService),
      const TypeMatcher<ExampleService>(),
    );
  });

  test('should use user-default value on ElementInjector.get', () async {
    final fixture = await NgTestBed<UsingElementInjector>().create();
    await fixture.update((comp) {
      final foo = comp.injector.get(#foo, 'someValue');
      expect(foo, 'someValue');
    });
  });

  test('should reify a typed OpaqueToken<T>', () async {
    final fixture = await NgTestBed<ReifiedMultiGenerics>().create();
    expect(
      fixture.assertOnlyInstance.usPresidents,
      const TypeMatcher<List<String>>(),
    );
    expect(fixture.text, '[George, Abraham]');
  });

  test('should reify a typed OpaqueToken<T> for a directive', () async {
    final fixture = await NgTestBed<UsesTypedTokensComponent>().create();
    expect(
      fixture.assertOnlyInstance.directive.arbitrary,
      const TypeMatcher<List<Arbitrary>>(),
    );
  });

  test('should support typed tokens that are inferred', () async {
    final fixture = await NgTestBed<SupportsInferredProviders>().create();
    expect(
      fixture.assertOnlyInstance.arbitrary,
      const TypeMatcher<List<Arbitrary>>(),
    );
  });

  test('should support MultiToken instead of multi: true', () async {
    final fixture = await NgTestBed<SupportsMultiToken>().create();
    expect(
      fixture.assertOnlyInstance.values,
      const TypeMatcher<List<String>>(),
    );
  });

  test('should support custom MultiToken', () async {
    final fixture = await NgTestBed<SupportsCustomMultiToken>().create();
    expect(
      fixture.assertOnlyInstance.values,
      const TypeMatcher<List<String>>(),
    );
  });

  test('should not consider Opaque/MultiToken the same token', () async {
    final fixture = await NgTestBed<NoClashTokens>().create();
    expect(fixture.assertOnlyInstance.fooTokenFromOpaque, hasLength(1));
    expect(fixture.assertOnlyInstance.fooTokenFromMulti, hasLength(1));
  });

  test('should not consider tokens with different types the same', () async {
    final fixture = await NgTestBed<SupportsTypedToken>().create();
    final value1 = fixture.assertOnlyInstance.injector.get(barTypedToken1);
    expect(value1, 1);
    final value2 = fixture.assertOnlyInstance.injector.get(barTypedToken2);
    expect(value2, true);
  });

  group('should support optional values', () {
    NgTestBed<UsingInjectAndOptional> testBed;

    setUp(() => testBed = NgTestBed<UsingInjectAndOptional>());

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
    final fixture = await NgTestBed<ProperTokenIdentity>().create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(aDynamicTokenNamedA), 'A');
    expect(injector.get(aDynamicTokenNamedB), 'B');
  });

  test('should treat unnamed tokens as acceptable', () async {
    final fixture = await NgTestBed<SupportsUnnamedToken>().create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(unnamedTokenOfDynamic), 1);
    expect(injector.get(unnamedTokenOfString), 2);
  });

  test('should support nested views with typed tokens', () async {
    var testBed = NgTestBed<SupportsTypedTokenInNestedViews>();
    testBed = testBed.addProviders([
      Provider(listOfStringToken, useValue: ['A', 'B', 'C']),
    ]);
    final fixture = await testBed.create();
    expect(fixture.assertOnlyInstance.childView.example, ['A', 'B', 'C']);
  });

  test('should throw a readable error message on a 1-node failure', () {
    final testBed = NgTestBed<WillFailInjecting1Node>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message on a 2-node failure', () {
    final testBed = NgTestBed<WillFailInjecting2Node>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService:\n  '
              '$InjectsMissingService ->\n  $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message on a child directive', () {
    final testBed = NgTestBed<WillFailCreatingChild>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService:\n  '
              '$WillFailInjecting1Node ->\n  $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message in an embedded template', () {
    final testBed = NgTestBed<WillFailCreatingChildInTemplate>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService:\n  '
              '$WillFailInjecting1Node ->\n  $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message when quering a child', () {
    final testBed = NgTestBed<WillFailQueryingServiceInTemplate>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService:\n  '
              '$InjectsMissingService ->\n  $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message following a factory', () {
    final testBed = NgTestBed<WillFailFollowingFactoryProvider>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService:\n  '
              '$InjectsMissingService ->\n  $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message following $ExistingProvider', () {
    final testBed = NgTestBed<WillFailFollowingExistingProvider>();
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains('No provider found for $MissingService:\n  '
              '$PrimeInjectsMissingService ->\n  $MissingService'),
        ),
      ),
    );
  });

  test('should throw a readable error message on a 2-node/parent failure', () {
    final testBed = NgTestBed<WillFailInjecting2NodeParent>().addProviders([
      Provider(
        InjectsMissingService,
        useFactory: (Object willNotBeCalled) => null,
        deps: const [
          MissingService,
        ],
      )
    ]);
    expect(
      () => testBed.create(),
      throwsA(
        predicate(
          (e) => '$e'.contains(''
              'No provider found for $MissingService:\n  '
              '$WillFailInjecting2NodeParent ->\n  '
              '$InjectsMissingService ->\n  $MissingService.'),
        ),
      ),
    );
  });

  test('should treat an OpaqueToken identical to @Inject', () async {
    final fixture = await NgTestBed<InjectsBaseUrl>().create();
    final InjectsBaseUrl service = fixture.assertOnlyInstance;
    expect(service.url, 'https://site.com/api/');
  });

  test('should support a custom OpaqueToken', () async {
    final fixture = await NgTestBed<InjectsXsrfToken>().create();
    final InjectsXsrfToken service = fixture.assertOnlyInstance;
    expect(service.token, 'ABC123');
  });

  test('should support modules in providers: const [ ... ]', () async {
    final fixture = await NgTestBed<SupportsModules>().create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(ExampleService), const TypeMatcher<ExampleService>());
    expect(injector.get(C), const C('Hello World'));
  });

  test('should support arbitrary const values in ValueProvider', () async {
    final testBed = NgTestBed<SupportsValueProviderWithArbitraryConst>();
    final fixture = await testBed.create();
    final component = fixture.assertOnlyInstance;
    expect(component.c1, isNotNull);
    expect(component.c2, isNotNull);
    expect(component.c2.name, '$TestConstPositionalArgs');
    expect(component.c3, isNotNull);
    expect(component.c3.name, '$TestConstNamedArgs');
    expect(component.c4, isNotNull);
    expect(component.c4.name, '$TestConstNamedArgs2');
  });
}

@Component(
  selector: 'test-parent',
  template: '<parent></parent>',
  directives: [
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
  directives: [
    CompChild1,
  ],
  providers: [
    A,
    B,
    Provider(C, useValue: C('oldC')),
  ],
)
class CompParent {
  @ViewChild(CompChild1)
  CompChild1 child1;
}

@Component(
  selector: 'child-1',
  template: '<child-2></child-2>',
  directives: [
    CompChild2,
  ],
  providers: [
    B,
    Provider(C, useValue: C('newC')),
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
  providers: [
    Provider(ExampleServiceOptionals, useClass: ExampleServiceOptionals),
  ],
)
class UsingInjectAndOptional {
  final ExampleServiceOptionals service;

  UsingInjectAndOptional(this.service);
}

const urlToken = OpaqueToken('urlToken');

class ExampleServiceOptionals {
  final String urlFromToken;

  ExampleServiceOptionals(
    @Inject(urlToken) @Optional() this.urlFromToken,
  );
}

const usPresidentsToken = OpaqueToken<String>('usPresidents');

@Component(
  selector: 'reified-multi-generics',
  providers: [
    Provider<String>(
      usPresidentsToken,
      useValue: 'George',
      multi: true,
    ),
    Provider<String>(
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

const arbitraryToken = OpaqueToken<Arbitrary>('arbitrary');

@Component(
  selector: 'uses-typed-tokens',
  directives: [UsesTypedTokensDirective],
  providers: [
    Provider<Arbitrary>(
      arbitraryToken,
      useValue: Arbitrary(1),
      multi: true,
    ),
    Provider<Arbitrary>(
      arbitraryToken,
      useValue: Arbitrary(2),
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
  providers: [
    ValueProvider.forToken(
      arbitraryToken,
      Arbitrary(1),
      multi: true,
    ),
  ],
  template: '',
)
class SupportsInferredProviders {
  final List<Arbitrary> arbitrary;

  SupportsInferredProviders(@Inject(arbitraryToken) this.arbitrary);
}

const usPresidentsMulti = MultiToken<String>('usPresidents');

@Component(
  selector: 'supports-multi-token',
  providers: [
    ValueProvider.forToken(usPresidentsMulti, 'George Washington'),
    ValueProvider.forToken(usPresidentsMulti, 'Abraham Lincoln'),
  ],
  template: '',
)
class SupportsMultiToken {
  final List<String> values;

  SupportsMultiToken(@Inject(usPresidentsMulti) this.values);
}

class CustomMultiToken extends MultiToken<String> {
  const CustomMultiToken();
}

@Component(
  selector: 'supports-multi-token',
  providers: [
    ValueProvider.forToken(CustomMultiToken(), 'A'),
    ValueProvider.forToken(CustomMultiToken(), 'B'),
  ],
  template: '',
)
class SupportsCustomMultiToken {
  final List<String> values;

  SupportsCustomMultiToken(@Inject(CustomMultiToken()) this.values);
}

const fooOpaqueToken = OpaqueToken<String>('fooToken');
const fooMultiToken = MultiToken<String>('fooToken');

@Component(
  selector: 'no-clash-tokens',
  providers: [
    ValueProvider.forToken(fooOpaqueToken, 'Hello', multi: true),
    ValueProvider.forToken(fooMultiToken, 'World'),
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

const barTypedToken1 = OpaqueToken<dynamic>('barTypedToken');
const barTypedToken2 = OpaqueToken<bool>('barTypedToken');

@Component(
  selector: 'supports-typed-token',
  providers: [
    ValueProvider.forToken(barTypedToken1, 1),
    ValueProvider.forToken(barTypedToken2, true),
  ],
  template: '',
)
class SupportsTypedToken {
  final Injector injector;

  SupportsTypedToken(this.injector);
}

const aDynamicTokenNamedA = OpaqueToken('A');
const aDynamicTokenNamedB = OpaqueToken('B');

@Component(
  selector: 'proper-token-identity',
  providers: [
    Provider(aDynamicTokenNamedA, useValue: 'A'),
    Provider(aDynamicTokenNamedB, useValue: 'B'),
  ],
  template: '',
)
class ProperTokenIdentity {
  final Injector injector;

  ProperTokenIdentity(this.injector);
}

@Injectable()
class ExampleService {}

@Component(
  selector: 'supports-implicit-class',
  providers: [
    Provider(ExampleService),
  ],
  template: '',
)
class SupportsImplicitClass {
  final Injector injector;

  SupportsImplicitClass(this.injector);
}

const unnamedTokenOfDynamic = OpaqueToken();
const unnamedTokenOfString = OpaqueToken<String>();

@Component(
  selector: 'supports-unnamed-token',
  providers: [
    Provider(unnamedTokenOfDynamic, useValue: 1),
    Provider(unnamedTokenOfString, useValue: 2),
  ],
  template: '',
)
class SupportsUnnamedToken {
  final Injector injector;

  SupportsUnnamedToken(this.injector);
}

const listOfStringToken = OpaqueToken<List<String>>('listOfString');

@Component(
  selector: 'supports-typed-token-in-nested-views',
  template: r'''
    <div *ngIf="someValue">
      <div *ngIf="someValue">
        <child-that-injects-token #tag></child-that-injects-token>
      </div>
    </div>
  ''',
  directives: [
    ChildThatInjectsTypedToken,
    NgIf,
  ],
)
class SupportsTypedTokenInNestedViews {
  @ViewChild('tag')
  ChildThatInjectsTypedToken childView;

  bool someValue = true;
}

@Component(
  selector: 'child-that-injects-token',
  template: '',
)
class ChildThatInjectsTypedToken {
  final List<String> example;

  ChildThatInjectsTypedToken(@Inject(listOfStringToken) this.example);
}

class MissingService {}

@Component(
  selector: 'will-fail-injecting-1-node',
  template: '',
)
class WillFailInjecting1Node {
  WillFailInjecting1Node(MissingService _);
}

class InjectsMissingService {
  InjectsMissingService(MissingService _);
}

@Component(
  selector: 'will-fail-injecting-2-node',
  providers: [
    Provider(
      InjectsMissingService,
    ),
  ],
  template: '',
)
class WillFailInjecting2Node {
  WillFailInjecting2Node(InjectsMissingService _);
}

@Component(
  selector: 'will-fail-injecting-2-node',
  template: '',
)
class WillFailInjecting2NodeParent {
  WillFailInjecting2NodeParent(InjectsMissingService _);
}

@Component(
  selector: 'will-fail-creating-child',
  template: r'''
    <will-fail-injecting-1-node></will-fail-injecting-1-node>
  ''',
  directives: [WillFailInjecting1Node],
)
class WillFailCreatingChild {}

@Component(
  selector: 'will-fail-creating-child',
  template: r'''
    <will-fail-injecting-1-node *ngIf="showChild"></will-fail-injecting-1-node>
  ''',
  directives: [
    NgIf,
    WillFailInjecting1Node,
  ],
)
class WillFailCreatingChildInTemplate {
  var showChild = true;
}

@Component(
  selector: 'will-fail-querying-service',
  template: r'''
    <lazy-provides-missing-service></lazy-provides-missing-service>
  ''',
  directives: [
    LazilyProvidesMissingService,
  ],
)
class WillFailQueryingServiceInTemplate {
  @ViewChild(LazilyProvidesMissingService, read: InjectsMissingService)
  InjectsMissingService willFailDuringQuery;
}

@Directive(
  selector: 'lazy-provides-missing-service',
  providers: [
    InjectsMissingService,
  ],
)
class LazilyProvidesMissingService {}

@Component(
  selector: 'will-fail-following-factory-provider',
  template: '',
  providers: [
    FactoryProvider(
      InjectsMissingService,
      WillFailFollowingFactoryProvider.aFactory,
    )
  ],
)
class WillFailFollowingFactoryProvider {
  static InjectsMissingService aFactory(MissingService d) =>
      InjectsMissingService(d);

  WillFailFollowingFactoryProvider(InjectsMissingService _);
}

@Component(
  selector: 'will-fail-following-factory-provider',
  template: '',
  providers: [
    ClassProvider(PrimeInjectsMissingService),
    ExistingProvider(InjectsMissingService, PrimeInjectsMissingService)
  ],
)
class WillFailFollowingExistingProvider {
  WillFailFollowingExistingProvider(InjectsMissingService _);
}

class PrimeInjectsMissingService extends InjectsMissingService {
  PrimeInjectsMissingService(MissingService d) : super(d);
}

const baseUrl = OpaqueToken<String>('baseUrl');

@Component(
  selector: 'injects-base-url',
  template: '',
  providers: [
    Provider(baseUrl, useValue: 'https://site.com/api/'),
  ],
)
class InjectsBaseUrl {
  final String url;

  // Identical to writing @Inject(baseUrl).
  InjectsBaseUrl(@baseUrl this.url);
}

class XsrfToken extends OpaqueToken<String> {
  const XsrfToken();
}

@Injectable()
@Component(
  selector: 'injects-xsrf-token',
  template: '',
  providers: [
    Provider(XsrfToken(), useValue: 'ABC123'),
  ],
)
class InjectsXsrfToken {
  final String token;

  InjectsXsrfToken(@XsrfToken() this.token);
}

@Component(
  selector: 'supports-modules',
  template: '',
  providers: [
    Module(
      include: [
        Module(
          provide: [
            ValueProvider(C, C('Hello World')),
          ],
        ),
      ],
      provide: [
        ClassProvider(ExampleService),
      ],
    ),
  ],
)
class SupportsModules {
  final Injector injector;

  SupportsModules(this.injector);
}

class TestConstNoArgs {
  const TestConstNoArgs();
}

class TestConstPositionalArgs {
  final String name;
  const TestConstPositionalArgs(this.name);
}

class TestConstNamedArgs {
  final String name;
  const TestConstNamedArgs({this.name});
}

class TestConstNamedArgs2 {
  final String name;
  const TestConstNamedArgs2({this.name});
}

const topLevelValue = TestConstNamedArgs2(name: 'TestConstNamedArgs2');
const topLevelProvider = ValueProvider(TestConstNamedArgs2, topLevelValue);

@Component(
  selector: 'supports-value-provider',
  template: '',
  providers: [
    ValueProvider(
      TestConstNoArgs,
      TestConstNoArgs(),
    ),
    ValueProvider(
      TestConstPositionalArgs,
      TestConstPositionalArgs('TestConstPositionalArgs'),
    ),
    ValueProvider(
      TestConstNamedArgs,
      TestConstNamedArgs(name: 'TestConstNamedArgs'),
    ),
    topLevelProvider,
  ],
)
class SupportsValueProviderWithArbitraryConst {
  final TestConstNoArgs c1;
  final TestConstPositionalArgs c2;
  final TestConstNamedArgs c3;
  final TestConstNamedArgs2 c4;

  SupportsValueProviderWithArbitraryConst(
    this.c1,
    this.c2,
    this.c3,
    this.c4,
  );
}
