import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'directive_test.template.dart' as ng;

/// Verifies whether injection through directives/components is correct.
void main() {
  tearDown(disposeAnyRunningTest);

  test('should use the proper provider bindings in a hierarchy', () async {
    final fixture = await NgTestBed(
      ng.createTestParentFactory(),
    ).create();
    late final B serviceB;
    late final A serviceA;
    await fixture.update((comp) {
      serviceB = comp.parent!.child1!.b;
      serviceA = comp.parent!.child1!.child2!.a;
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
    final fixture = await NgTestBed(
      ng.createSupportsImplicitClassFactory(),
    ).create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(
      injector.get(ExampleService),
      const TypeMatcher<ExampleService>(),
    );
  });

  test('should use user-default value on ElementInjector.get', () async {
    final fixture = await NgTestBed(
      ng.createUsingElementInjectorFactory(),
    ).create();
    await fixture.update((comp) {
      final foo = comp.injector.get(#foo, 'someValue');
      expect(foo, 'someValue');
    });
  });

  test('should support MultiToken', () async {
    final fixture = await NgTestBed(
      ng.createSupportsMultiTokenFactory(),
    ).create();
    expect(
      fixture.assertOnlyInstance.values,
      const TypeMatcher<List<String>>(),
    );
  });

  test('should support custom MultiToken', () async {
    final fixture = await NgTestBed(
      ng.createSupportsCustomMultiTokenFactory(),
    ).create();
    expect(
      fixture.assertOnlyInstance.values,
      const TypeMatcher<List<String>>(),
    );
  });

  test('should not consider Opaque/MultiToken the same token', () async {
    final fixture = await NgTestBed(
      ng.createNoClashTokensFactory(),
    ).create();
    expect(
      fixture.assertOnlyInstance.fooTokenFromOpaque,
      isNot(fixture.assertOnlyInstance.fooTokenFromMulti),
    );
  });

  test('should not consider tokens with different types the same', () async {
    final fixture = await NgTestBed(
      ng.createSupportsTypedTokenFactory(),
    ).create();
    final value1 = fixture.assertOnlyInstance.injector.get(barTypedToken1);
    expect(value1, 1);
    final value2 = fixture.assertOnlyInstance.injector.get(barTypedToken2);
    expect(value2, true);
  });

  group('should support optional values', () {
    late NgTestBed<UsingInjectAndOptional> testBed;

    setUp(
      () => testBed = NgTestBed(
        ng.createUsingInjectAndOptionalFactory(),
      ),
    );

    test('when provided', () async {
      testBed = testBed.addInjector(
        (i) => Injector.map({
          urlToken: 'https://google.com',
        }, i),
      );
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
    final fixture = await NgTestBed(
      ng.createProperTokenIdentityFactory(),
    ).create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(aDynamicTokenNamedA), 'A');
    expect(injector.get(aDynamicTokenNamedB), 'B');
  });

  test('should treat unnamed tokens as acceptable', () async {
    final fixture = await NgTestBed(
      ng.createSupportsUnnamedTokenFactory(),
    ).create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(unnamedTokenOfDynamic), 1);
    expect(injector.get(unnamedTokenOfString), 2);
  });

  test('should support nested views with typed tokens', () async {
    var testBed = NgTestBed(
      ng.createSupportsTypedTokenInNestedViewsFactory(),
    );
    testBed = testBed.addInjector(
      (i) => Injector.map({
        listOfStringToken: ['A', 'B', 'C'],
      }, i),
    );
    final fixture = await testBed.create();
    expect(fixture.assertOnlyInstance.childView!.example, ['A', 'B', 'C']);
  });

  test('should throw a readable error message on a 1-node failure', () {
    final testBed = NgTestBed(
      ng.createWillFailInjecting1NodeFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailInjecting2NodeFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailCreatingChildFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailCreatingChildInTemplateFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailQueryingServiceInTemplateFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailFollowingFactoryProviderFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailFollowingExistingProviderFactory(),
    );
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
    final testBed = NgTestBed(
      ng.createWillFailInjecting2NodeParentFactory(),
    ).addInjector(
      (i) => ReflectiveInjector.resolveStaticAndCreate([
        Provider(
          InjectsMissingService,
          useFactory: (Object willNotBeCalled) => null,
          deps: const [
            MissingService,
          ],
        )
      ], i),
    );
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
    final fixture = await NgTestBed(
      ng.createInjectsBaseUrlFactory(),
    ).create();
    final service = fixture.assertOnlyInstance;
    expect(service.url, 'https://site.com/api/');
  });

  test('should support a custom OpaqueToken', () async {
    final fixture = await NgTestBed(
      ng.createInjectsXsrfTokenFactory(),
    ).create();
    final service = fixture.assertOnlyInstance;
    expect(service.token, 'ABC123');
  });

  test('should support modules in providers: const [ ... ]', () async {
    final fixture = await NgTestBed(
      ng.createSupportsModulesFactory(),
    ).create();
    final injector = fixture.assertOnlyInstance.injector;
    expect(injector.get(ExampleService), const TypeMatcher<ExampleService>());
    expect(injector.get(C), const C('Hello World'));
  });

  test('should support arbitrary const values in ValueProvider', () async {
    final testBed = NgTestBed(
      ng.createSupportsValueProviderWithArbitraryConstFactory(),
    );
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

  group('should support void and Null', () {
    test('in a @Component', () async {
      final fixture = await NgTestBed(
        ng.createComponentInjectorFactory(),
      ).create();
      expect(
        fixture.assertOnlyInstance.aListOfNull,
        const [null],
      );
      expect(
        fixture.assertOnlyInstance.aListOfVoid,
        const [1],
      );
      expect(
        fixture.assertOnlyInstance.aListOfListOfNull,
        const [
          [null]
        ],
      );
      expect(
        fixture.assertOnlyInstance.aListOfListOfVoid,
        const [
          [2]
        ],
      );
    });

    test('in a @GenerateInjector', () async {
      final injector = generatedInjector(Injector.empty());
      expect(injector.get(listOfNull), const [null]);
      expect(injector.get(listOfVoid), const [1]);
      expect(injector.get(listOfListOfNull), const [
        [null]
      ]);
      expect(injector.get(listOfListOfVoid), const [
        [2]
      ]);
    });
  });

  group('should correctly type a provider', () {
    NgTestBed<SomeInterface> testBed;
    NgTestFixture<SomeInterface> fixture;
    List<Object> interfaces;

    test('implicit', () async {
      testBed = NgTestBed(
        ng.createCompProvidesImplicitTypesFactory(),
      );
      fixture = await testBed.create();

      interfaces =
          fixture.assertOnlyInstance.injector.provideToken(someInterfaces);
      expect(interfaces, isNotEmpty);
      expect(
        interfaces,
        isTypedList,
      );
    });

    test('explicit', () async {
      testBed = NgTestBed(
        ng.createCompProvidesExplicitTypesFactory(),
      );
      fixture = await testBed.create();

      interfaces =
          fixture.assertOnlyInstance.injector.provideToken(someInterfaces);
      expect(interfaces, isNotEmpty);
      expect(
        interfaces,
        isTypedList,
      );
    });
  });

  test('should use the provided type with component providers', () async {
    final testBed = NgTestBed(
      ng.createCompProvidesUsPresidentsFactory(),
    );
    final fixture = await testBed.create();
    final childComp = fixture.assertOnlyInstance.child;

    // Prior to the fix of #920, this was always provided as List<dynamic>.
    expect(
      childComp!.injectedList,
      const TypeMatcher<List<String>>(),
      reason: 'Got ${childComp.injectedList.runtimeType} not List<String>',
    );
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
  CompParent? parent;
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
  CompChild1? child1;
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
  CompChild2? child2;
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
  final String? urlFromToken;

  ExampleServiceOptionals(
    @Inject(urlToken) @Optional() this.urlFromToken,
  );
}

class Arbitrary {
  final int value;

  const Arbitrary(this.value);
}

const arbitraryToken = OpaqueToken<Arbitrary>('arbitrary');

@Directive(
  selector: '[arbitrary]',
)
class UsesTypedTokensDirective {
  final List<Arbitrary> arbitrary;

  UsesTypedTokensDirective(@Inject(arbitraryToken) this.arbitrary);
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

const fooOpaqueToken = OpaqueToken<List<String>>('fooToken');
const fooMultiToken = MultiToken<String>('fooToken');

@Component(
  selector: 'no-clash-tokens',
  providers: [
    ValueProvider.forToken(fooOpaqueToken, ['Hello']),
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

const barTypedToken1 = OpaqueToken<Object>('barTypedToken');
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
  ChildThatInjectsTypedToken? childView;

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
  InjectsMissingService? willFailDuringQuery;
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
  const TestConstNamedArgs({required this.name});
}

class TestConstNamedArgs2 {
  final String name;
  const TestConstNamedArgs2({required this.name});
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

const listOfVoid = OpaqueToken<List<void>>('listOfVoid');
// ignore: prefer_void_to_null
const listOfNull = OpaqueToken<List<Null>>('listOfNull');

const listOfListOfVoid = MultiToken<List<void>>('listOfListOfVoid');

// ignore: prefer_void_to_null
const listOfListOfNull = MultiToken<List<Null>>('listOfListOfNull');

const _testVoidTokenProviders = [
  ValueProvider.forToken(listOfVoid, [1]),
  ValueProvider.forToken(listOfNull, [null]),
  ValueProvider.forToken(listOfListOfVoid, [2]),
  ValueProvider.forToken(listOfListOfNull, [null]),
];

@GenerateInjector([_testVoidTokenProviders])
final InjectorFactory generatedInjector = ng.generatedInjector$Injector;

@Component(
  selector: 'comp',
  providers: [_testVoidTokenProviders],
  template: '',
)
class ComponentInjector {
  // Lack of types on these fields (i.e. List<void> or List<Null>) is due to
  // https://github.com/angulardart/angular/issues/1436
  final Object aListOfVoid;
  final Object aListOfNull;

  final List<List<void>> aListOfListOfVoid;

  // ignore: prefer_void_to_null
  final List<List<Null>> aListOfListOfNull;

  ComponentInjector(
    @Inject(listOfVoid) this.aListOfVoid,
    @Inject(listOfNull) this.aListOfNull,
    @Inject(listOfListOfVoid) this.aListOfListOfVoid,
    @Inject(listOfListOfNull) this.aListOfListOfNull,
  );
}

const isTypedList = TypeMatcher<List<SomeInterface>>();
const someInterfaces = MultiToken<SomeInterface>('someInterfaces');

abstract class SomeInterface {
  Injector get injector;
}

@Component(
  selector: 'comp-provides-implicit-types',
  providers: [
    ExistingProvider /* IMPLICIT: <SomeInterface> */ .forToken(
      someInterfaces,
      CompProvidesImplicitTypes,
    ),
  ],
  template: '',
)
class CompProvidesImplicitTypes implements SomeInterface {
  @override
  final Injector injector;

  CompProvidesImplicitTypes(this.injector);
}

@Component(
  selector: 'comp-provides-explicit-types',
  providers: [
    ExistingProvider<List<SomeInterface>>.forToken(
      someInterfaces,
      CompProvidesExplicitTypes,
    ),
  ],
  template: '',
)
class CompProvidesExplicitTypes implements SomeInterface {
  @override
  final Injector injector;

  CompProvidesExplicitTypes(this.injector);
}

const usPresidents = OpaqueToken<List<String>>('usPresidents');

@Component(
  selector: 'comp',
  directives: [
    ChildComp,
  ],
  providers: [
    Provider<List<String>>(usPresidents, useValue: [
      'George Washington',
      'Abraham Lincoln',
    ]),
  ],
  template: '<child></child>',
)
class CompProvidesUsPresidents {
  @ViewChild(ChildComp)
  ChildComp? child;
}

@Component(
  selector: 'child',
  template: '',
)
class ChildComp {
  // Intentionally not List<String>, that is the regression test :)
  final Object injectedList;

  ChildComp(@usPresidents this.injectedList);
}
