// ignore_for_file: invalid_use_of_protected_member

import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';
import 'package:angular/src/di/injector.dart';
import 'package:angular/src/reflector.dart' as reflector;
import 'package:angular_test/angular_test.dart';

import 'injector_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('Injector', () {
    test('.get should delegate token to .inject', () {
      final injector = CaptureInjectInjector();
      injector.get(ExampleService);
      expect(injector.lastToken, ExampleService);
      expect(injector.lastOrElse, throwIfNotFound);
    });

    group('.get should delegate', () {
      late CaptureInjectInjector injector;

      setUp(() => injector = CaptureInjectInjector());

      test('token to .inject', () {
        injector.get(ExampleService);
        expect(injector.lastToken, ExampleService);
        expect(injector.lastOrElse, throwIfNotFound);
      });

      test('orElse to .inject (partially, not API compatible)', () {
        injector.get(ExampleService, #customValue);
        expect(injector.lastToken, ExampleService);
        expect(injector.lastOrElse, #customValue);
      });
    });

    group('.empty', () {
      test('should throw by default', () {
        final i = Injector.empty();
        expect(
          () => i.get(ExampleService),
          throwsNoProviderError,
        );
        expect(
          () => i.provideType<ExampleService>(ExampleService),
          throwsNoProviderError,
        );
        expect(
          () => i.injectFromSelf(ExampleService),
          throwsNoProviderError,
        );
        expect(
          () => i.injectFromAncestry(ExampleService),
          throwsNoProviderError,
        );
        expect(
          () => i.injectFromParent(ExampleService),
          throwsNoProviderError,
        );
      });

      test('should throw a readable message with injection fails', () {
        // Anything but injector.get(Injector) will fail here.
        final injector = Injector.empty();
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.endsWith('No provider found for $ExampleService'),
            ),
          ),
        );
      });

      test('should throw a readable message even with a parent injector', () {
        final parent = Injector.empty();
        final child = Injector.map({}, parent);
        expect(
          () => child.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.endsWith('No provider found for $ExampleService'),
            ),
          ),
        );
      });

      test('should use orElse if provided', () {
        final i = Injector.empty();
        expect(i.get(ExampleService, 123), 123);
        expect(i.injectFromSelfOptional(ExampleService, 123), 123);
        expect(i.injectFromAncestryOptional(ExampleService, 123), 123);
        expect(i.injectFromParentOptional(ExampleService, 123), 123);
      });

      test('should fallback to the parent injector if provided', () {
        final instance = ExampleService();
        final parent = Injector.map({ExampleService: instance});
        final i = Injector.map({}, parent);
        expect(i.get(ExampleService), instance);
        expect(i.provideType<ExampleService>(ExampleService), instance);
        expect(
          () => i.injectFromSelf(ExampleService),
          throwsNoProviderError,
        );
        expect(i.injectFromAncestry(ExampleService), instance);
        expect(i.injectFromParent(ExampleService), instance);
      });

      test('should return itself if Injector is passed', () {
        final i = Injector.empty();
        expect(i.get(Injector), i);
      });
    });

    group('.map', () {
      test('should return a provided key-value pair', () {
        final instance = ExampleService();
        final i = Injector.map({ExampleService: instance});
        expect(i.get(ExampleService), instance);
        expect(i.provideType<ExampleService>(ExampleService), instance);
        expect(i.injectFromSelf(ExampleService), instance);
        expect(
          () => i.injectFromAncestry(ExampleService),
          throwsNoProviderError,
        );
        expect(
          () => i.injectFromParent(ExampleService),
          throwsNoProviderError,
        );
      });

      test('should return itself if Injector is passed', () {
        final i = Injector.map({});
        expect(i.get(Injector), i);
      });

      test('should throw a readable error message on a failure', () {
        final injector = Injector.map({});
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.endsWith('No provider found for $ExampleService'),
            ),
          ),
        );
      });
    });

    group('ReflectiveInjector', () {
      setUpAll(() {
        reflector.registerFactory(ExampleService, () => ExampleService());
        reflector.registerFactory(ExampleService2, () => ExampleService2());
        reflector.registerDependencies(createListWith, [
          [String]
        ]);
      });

      test('should resolve a Type', () {
        final i = ReflectiveInjector.resolveAndCreate([ExampleService]);
        expect(i.get(ExampleService), const TypeMatcher<ExampleService>());
      });

      test('should resolve a Provider', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(ExampleService),
        ]);
        expect(i.get(ExampleService), const TypeMatcher<ExampleService>());
      });

      test('should resolve a Provider.useClass', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(ExampleService, useClass: ExampleService2),
        ]);
        expect(i.get(ExampleService), const TypeMatcher<ExampleService2>());
      });

      test('should resolve a Provider.useValue', () {
        final serviceValue = ExampleService();
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(ExampleService, useValue: serviceValue),
        ]);
        expect(i.get(ExampleService), serviceValue);
      });

      test('should resolve a Provider.useFactory', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(ExampleService, useFactory: createExampleService),
        ]);
        expect(i.get(ExampleService), const TypeMatcher<ExampleService>());
      });

      test('should resolve a Provider.useFactory with deps', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(String, useValue: 'Hello World'),
          Provider(List, useFactory: createListWith),
        ]);
        expect(i.get(List), ['Hello World']);
      });

      test('should resolve a Provider.useFactory with manual deps', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(#fooBar, useValue: 'Hello World'),
          Provider(List, useFactory: createListWith, deps: [#fooBar]),
        ]);
        expect(i.get(List), ['Hello World']);
      });

      test('should resolve a Provider.useExisting', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(ExampleService2),
          Provider(ExampleService, useExisting: ExampleService2),
        ]);
        expect(i.get(ExampleService), i.get(ExampleService2));
      });

      test('should resolve a multi binding', () {
        final fooBar = MultiToken<Object>('fooBar');
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(fooBar, useValue: 1),
          Provider(fooBar, useValue: 2),
        ]);
        expect(i.get(fooBar), [1, 2]);
      });

      test('should resolve @Optional', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(List, useFactory: createListWithOptional),
        ]);
        expect(i.get(List), [null]);
      });

      test('should inject things in order of most-recently added', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(#a, useValue: 1),
          Provider(#a, useValue: 2),
        ]);
        expect(i.get(#a), 2);
      });

      test('should return itself for "Injector"', () {
        final i = ReflectiveInjector.resolveAndCreate([
          Provider(#theInjector, useFactory: (i) => [i], deps: [Injector]),
        ]);
        expect(i.get(#theInjector), [i]);
      });

      test('should thrown when a provider was not found', () {
        final i = ReflectiveInjector.resolveAndCreate([]);
        expect(() => i.get(#ABC), throwsNoProviderError);
      });

      test('should support resolveAndCreateChild', () {
        final oldC = C('oldC');
        final parent = ReflectiveInjector.resolveAndCreate([
          A,
          B,
          Provider(C, useValue: oldC),
        ]);
        final newC = C('newC');
        final child1 = parent.resolveAndCreateChild([
          B,
          Provider(C, useValue: newC),
        ]);
        final newB = child1.provideType<B>(B);
        expect(newB.c, newC, reason: 'Expected a new "C" binding');
        final child2 = child1.resolveAndCreateChild([
          Provider(B, useValue: newB),
        ]);
        final newA = child2.get(A);
        expect(newA.b, isNot(newB), reason: 'Expected an old "B" binding');
        expect(newA.b.c, oldC, reason: 'Expected an old "C" binding');
      });

      test('should support MultiToken instead of multi: true', () {
        const usPresidentsMulti = MultiToken<String>('usPresidents');
        final injector = ReflectiveInjector.resolveAndCreate([
          const ValueProvider.forToken(usPresidentsMulti, 'George W.'),
          const ValueProvider.forToken(usPresidentsMulti, 'Abraham L.'),
        ]);
        expect(
          injector.get(usPresidentsMulti),
          const TypeMatcher<List<String>>(),
        );
      });

      test('should consider opaque tokens with different types unique', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(typedTokenOfDynamic, useValue: 1),
          const Provider(typedTokenOfString, useValue: 2),
        ]);
        expect(injector.get(typedTokenOfDynamic), 1);
        expect(injector.get(typedTokenOfString), 2);
      });

      test('should consider opaque tokens with different nested types', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(typedTokenOfListDynamic, useValue: 3),
          const Provider(typedTokenOfListString, useValue: 4),
        ]);
        expect(injector.get(typedTokenOfListDynamic), 3);
        expect(injector.get(typedTokenOfListString), 4);
      });

      test('should consider Provider(T) as Provider(T, useClass: T)', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(ExampleService),
        ]);
        expect(
          injector.get(ExampleService),
          const TypeMatcher<ExampleService>(),
        );
      });

      test('should accept unnammed tokens', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(unnamedTokenOfDynamic, useValue: 1),
          const Provider(unnamedTokenOfString, useValue: 2),
        ]);
        expect(injector.get(unnamedTokenOfDynamic), 1);
        expect(injector.get(unnamedTokenOfString), 2);
      });

      test('should throw a readable error message on a 1-node failure', () {
        final injector = ReflectiveInjector.resolveAndCreate([]);
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.endsWith('No provider found for $ExampleService'),
            ),
          ),
        );
      });

      test('should throw a readable error message on a 2-node failure', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          Provider(
            ExampleService,
            useFactory: (void willNeverBeCalled) => null,
            deps: const [ExampleService2],
          ),
        ]);
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.contains(''
                  'No provider found for $ExampleService2:\n  '
                  '$ExampleService ->\n  $ExampleService2.'),
            ),
          ),
        );
      });

      test('should throw a readable error message on a 3-node failure', () {
        // ExampleService -->
        //   ExampleService2 -->
        //     ExampleService3 + ExampleService4
        //
        // ... where ExampleService4 is missing.
        final injector = ReflectiveInjector.resolveAndCreate([
          Provider(
            ExampleService,
            useFactory: (void willNeverBeCalled) => null,
            deps: const [ExampleService2],
          ),
          Provider(
            ExampleService2,
            useFactory: (void willNeverBeCalled) => null,
            deps: const [ExampleService3, ExampleService4],
          ),
          Provider(
            ExampleService3,
            useValue: ExampleService3(),
          ),
        ]);
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.contains(''
                  'No provider found for $ExampleService4:\n  '
                  '$ExampleService ->\n  $ExampleService2 ->\n  '
                  '$ExampleService4.'),
            ),
          ),
        );
      });

      test('should treat an OpaqueToken identical to @Inject', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(baseUrl, useValue: 'https://site.com/api/'),
          InjectsBaseUrl,
        ]);
        final service = injector.provideType<InjectsBaseUrl>(InjectsBaseUrl);
        expect(service.url, 'https://site.com/api/');
      });

      test('should support a user type that extends OpaqueToken', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(XsrfToken(), useValue: 'ABC123'),
          InjectsXsrfToken,
        ]);
        expect(injector.get(const XsrfToken()), 'ABC123');
        final service = injector.provideType<InjectsXsrfToken>(
          InjectsXsrfToken,
        );
        expect(service.token, 'ABC123');
      });

      test('should support a Module class instead of a List', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Module(
            include: [
              Module(
                provide: [
                  ValueProvider(ExampleService, ExampleService()),
                ],
              ),
            ],
            provide: [
              ValueProvider(ExampleService2, ExampleService2()),
              ExistingProvider(ExampleService, ExampleService2),
            ],
          ),
        ]);
        expect(
          injector.get(ExampleService),
          const TypeMatcher<ExampleService2>(),
        );
      });
    });

    group('.generate', () {
      final injector = exampleGenerated(Injector.empty());

      test('should consider Provider(T) as Provider(T, useClass: T)', () {
        expect(
          injector.get(ExampleService2),
          const TypeMatcher<ExampleService2>(),
        );
      });

      test('should support "useClass"', () {
        expect(
          injector.get(ExampleService),
          const TypeMatcher<ExampleService2>(),
        );
      });

      group('should support "useValue" to a', () {
        test('boolean', () {
          expect(injector.get(booleanToken), true);
        });

        test('number', () {
          expect(injector.get(numberToken), 1234);
        });

        test('string', () {
          expect(injector.get(stringToken), 'Hello World');
        });
      });

      test('should support MultiToken', () {
        final result = injector.get(multiStringToken);
        expect(
          result,
          const TypeMatcher<List<String>>(),
          reason: 'List<String> expected, got $result of ${result.runtimeType}',
        );
        expect(result, ['A', 'B']);
      });

      test('should support a custom MultiToken', () {
        final result = injector.get(const CustomMultiString());
        expect(
          result,
          const TypeMatcher<List<String>>(),
          reason: 'List<String> expected, got $result of ${result.runtimeType}',
        );
        expect(result, ['C', 'D']);
      });

      test('should consider opaque tokens with different types unique', () {
        expect(injector.get(typedTokenOfDynamic), 1);
        expect(injector.get(typedTokenOfString), 2);
      });

      test('should consider opaque tokens with nested types unique', () {
        expect(injector.get(typedTokenOfListDynamic), 3);
        expect(injector.get(typedTokenOfListString), 4);
      });

      test('should support unnamed tokens', () {
        expect(injector.get(unnamedTokenOfDynamic), 5);
        expect(injector.get(unnamedTokenOfString), 6);
      });

      test('should throw a readable error message on a 1-node failure', () {
        expect(
          () => injector.get(MissingService),
          throwsA(
            predicate(
              (e) => '$e'.endsWith('No provider found for $MissingService'),
            ),
          ),
        );
      });

      test('should throw a readable error message on a 2-node failure', () {
        expect(
          () => injector.get(ExampleService3),
          throwsA(
            predicate(
              (e) => '$e'.contains(''
                  'No provider found for $MissingService:\n  '
                  '$ExampleService3 ->\n  $MissingService.'),
            ),
          ),
        );
      });

      test('should throw a readable error message on a 3-node failure', () {
        expect(
          () => injector.get(ExampleService4),
          throwsA(
            predicate(
              (e) => '$e'.contains(''
                  'No provider found for $MissingService:\n  '
                  '$ExampleService4 ->\n  $ExampleService3 ->\n  '
                  '$MissingService.'),
            ),
          ),
        );
      });

      test('should treat an OpaqueToken identical to @Inject', () {
        final service = injector.provideType<InjectsBaseUrl>(InjectsBaseUrl);
        expect(service.url, 'https://site.com/api/');
      });

      test('should support a user type that extends OpaqueToken', () {
        expect(injector.get(const XsrfToken()), 'ABC123');
        final service = injector.provideType<InjectsXsrfToken>(
          InjectsXsrfToken,
        );
        expect(service.token, 'ABC123');
      });

      test('should support Module', () {
        expect(
          exampleFromModule(Injector.empty()).get(ExampleService),
          const TypeMatcher<ExampleService2>(),
        );
      });

      test('should support arbitrary const values in ValueProvider', () {
        final injector = valueProviderExamples(Injector.empty());
        final c1 = injector.provideType<TestConstNoArgs>(
          TestConstNoArgs,
        );
        final c2 = injector.provideType<TestConstPositionalArgs>(
          TestConstPositionalArgs,
        );
        final c3 = injector.provideType<TestConstNamedArgs>(
          TestConstNamedArgs,
        );
        final c4 = injector.provideType<TestConstNamedArgs2>(
          TestConstNamedArgs2,
        );
        expect(c1, isNotNull);
        expect(c2, isNotNull);
        expect(c2.name, '$TestConstPositionalArgs');
        expect(c3, isNotNull);
        expect(c3.name, '$TestConstNamedArgs');
        expect(c4, isNotNull);
        expect(c4.name, '$TestConstNamedArgs2');
      });
    });

    test('should de-duplicate tokens preferring the last provider', () {
      final injector = tokenOrdering(Injector.empty());
      expect(injector.get(duplicateToken), 'B');
      expect(injector.get(duplicateMulti), ['A', 'B']);
    });

    group('Dynamic (uses initReflector)', () {
      late ReflectiveInjector parentInjector;

      setUp(() {
        parentInjector = ReflectiveInjector.resolveAndCreate([
          ClassProvider(Model),
          ValueProvider(Place, Place('Parent')),
        ]);
      });

      test('should have the expected bindings at the parent level', () {
        expect((parentInjector.get(Model) as Model).place.name, 'Parent');
      });

      test('should have the expected bindings at the child level', () {
        final childInjector = parentInjector.resolveAndCreateChild([
          ValueProvider(Place, Place('Child')),
        ]);
        expect(
          // ignore: deprecated_member_use
          (childInjector.resolveAndInstantiate(Model) as Model).place.name,
          'Child',
        );
      });
    });

    group('Static (no initReflector)', () {
      late ReflectiveInjector parentInjector;

      final modelProvider = FactoryProvider(
        Model,
        (Place place) => Model(place),
        deps: const [Place],
      );

      setUp(() {
        parentInjector = ReflectiveInjector.resolveStaticAndCreate([
          modelProvider,
          ValueProvider(Place, Place('Parent')),
        ]);
      });

      test('should have the expected bindings at the parent level', () {
        expect((parentInjector.get(Model) as Model).place.name, 'Parent');
      });

      test('should have the expected bindings at the child level', () {
        final childInjector = parentInjector.resolveAndCreateChild([
          ValueProvider(Place, Place('Child')),
        ]);
        expect(
          // ignore: deprecated_member_use
          (childInjector.resolveAndInstantiate(modelProvider) as Model)
              .place
              .name,
          'Child',
        );
      });
    });
  });

  group('root Injector overrides', () {
    void _testOverrideExceptionHandler(Injector appInjector) {
      // Normally errors here are forwarded to the ExceptionHandler.
      //
      // In the case of #1227, we accidentally always used the default
      // ExceptionHandler (BrowserExceptionHandler), meaning the user-defined
      // handler was ignored.
      (appInjector.get(NgZone) as NgZone).runGuarded(() {
        throw _IntentionalError();
      });
      expect(
        _CustomExceptionHandler.lastCaught,
        const TypeMatcher<_IntentionalError>(),
      );
    }

    // This is relied on by internal clients until we introduce a sharding API.
    test('rootInjector should allow overriding ExceptionHandler', () {
      _testOverrideExceptionHandler(
        rootInjector((parent) {
          return Injector.map({
            ExceptionHandler: _CustomExceptionHandler(),
          }, parent);
        }),
      );
    });
  });

  /// This regression test demonstrates why `View.injectorGet()` must null-check
  /// the `nodeIndex` argument, a rare and complex case that requires a number
  /// of conditions to be met.
  ///
  ///   (1) Create a component whose template contains a top-level view
  ///   container; this ensures the view container has a null parent index.
  ///
  ///   (2) Add directive(s) with multiple providers to any node in the
  ///   component's template with at least one child node; this ensures that a
  ///   range check on `nodeIndex` is generated in `injectorGetInternal` and not
  ///   skipped due to short-circuit evaluation when a node only has one
  ///   provider and the token doesn't match. This range check is what will
  ///   throw if `nodeIndex` is null.
  ///
  ///   (3) Inject a dependency via the top-level view container's
  ///   `parentInjector`. This causes the null parent index to pass from
  ///   `ElementInjector.provideUntyped()` to `View.injectorGet()`.
  test('View.injectorGet() should handle a null nodeIndex argument', () async {
    final testValue = 'Hello world!';
    final testBed = NgTestBed(
      ng.createTestComponentFactory(),
      rootInjector: (parent) => Injector.map({testToken: testValue}, parent),
    );
    final testFixture = await testBed.create();
    final testComponent = testFixture.assertOnlyInstance;
    expect(
      // This parent injector, an `ElementInjector`, passes a null nodeIndex
      // parameter to `View.injectorGet()`. Note that while this looks like a
      // bizarre use case that might not seem worth supporting, this is the
      // simplest reproduction of this pattern that can be achieved far more
      // indirectly via declarative means. Clients do depend on this behavior.
      testComponent.viewContainerRef!.parentInjector.provideToken(testToken),
      testValue,
    );
  });
}

/// Implementation of [Injector] that captures [lastToken] and [lastOrElse].
class CaptureInjectInjector extends HierarchicalInjector implements Injector {
  Object? lastToken;
  Object? lastOrElse;

  CaptureInjectInjector() : super(Injector.empty());

  @override
  Object? injectFromSelfOptional(
    Object token, [
    Object? orElse = throwIfNotFound,
  ]) {
    lastToken = token;
    lastOrElse = orElse;
    return null;
  }
}

class ExampleService {
  const ExampleService();
}

class ExampleService2 implements ExampleService {
  const ExampleService2();
}

class ExampleService3 {}

class ExampleService4 {}

class MissingService {}

const stringToken = OpaqueToken('stringToken');
const numberToken = OpaqueToken('numberToken');
const booleanToken = OpaqueToken('booleanToken');
const simpleConstToken = OpaqueToken('simpleConstToken');
const multiStringToken = MultiToken<String>('multiStringToken');

// We are going to expect these are different bindings.
const typedTokenOfDynamic = OpaqueToken('typedToken');
const typedTokenOfString = OpaqueToken<String>('typedToken');

const typedTokenOfListDynamic = OpaqueToken<List<dynamic>>('typedToken');
const typedTokenOfListString = OpaqueToken<List<String>>('typedToken');

const unnamedTokenOfDynamic = OpaqueToken();
const unnamedTokenOfString = OpaqueToken<String>();

Never willNeverBeCalled1(Object _) => throw '';
Never willNeverBeCalled2(Object _, Object __) => throw '';

class CustomMultiString extends MultiToken<String> {
  const CustomMultiString();
}

@GenerateInjector([
  Provider(ExampleService, useClass: ExampleService2),
  Provider(ExampleService2),
  Provider(stringToken, useValue: 'Hello World'),
  Provider(numberToken, useValue: 1234),
  Provider(booleanToken, useValue: true),
  Provider(simpleConstToken, useValue: ExampleService()),

  // Example of a runtime failure; MissingService
  Provider(
    ExampleService3,
    useFactory: willNeverBeCalled1,
    deps: [MissingService],
  ),

  // Example of a runtime failure; ExampleService3 -> MissingService.
  Provider(
    ExampleService4,
    useFactory: willNeverBeCalled2,
    // Will find ExampleService2, ExampleService3 will fail (see above).
    deps: [ExampleService2, ExampleService3],
  ),

  ValueProvider.forToken(multiStringToken, 'A'),
  ValueProvider.forToken(multiStringToken, 'B'),
  ValueProvider.forToken(CustomMultiString(), 'C'),
  ValueProvider.forToken(CustomMultiString(), 'D'),

  // We are going to expect these are different bindings.
  Provider(typedTokenOfDynamic, useValue: 1),
  Provider(typedTokenOfString, useValue: 2),

  // We are going to expect these are also different bindings.
  Provider(typedTokenOfListDynamic, useValue: 3),
  Provider(typedTokenOfListString, useValue: 4),

  // We are going to expect these are also different bindings.
  Provider(unnamedTokenOfDynamic, useValue: 5),
  Provider(unnamedTokenOfString, useValue: 6),

  // Tests that @Inject(baseUrl) === @baseUrl
  Provider(baseUrl, useValue: 'https://site.com/api/'),
  InjectsBaseUrl,

  // Tests that class T extends OpaqueToken
  Provider(XsrfToken(), useValue: 'ABC123'),
  InjectsXsrfToken,
])
final InjectorFactory exampleGenerated = ng.exampleGenerated$Injector;

@GenerateInjector.fromModules([
  Module(
    include: [
      Module(
        provide: [
          ValueProvider(ExampleService, ExampleService()),
        ],
      ),
    ],
    provide: [
      ValueProvider(ExampleService2, ExampleService2()),
      ExistingProvider(ExampleService, ExampleService2),
    ],
  ),
])
final InjectorFactory exampleFromModule = ng.exampleFromModule$Injector;

ExampleService createExampleService() => ExampleService();

List<String> createListWith(String item) => [item];

@Injectable()
List<String?> createListWithOptional(@Optional() String? missing) => [missing];

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

  C(this.debugMessage);

  @override
  String toString() => 'C: $debugMessage';
}

const baseUrl = OpaqueToken<String>('baseUrl');

@Injectable()
class InjectsBaseUrl {
  final String url;

  // Identical to writing @Inject(baseUrl).
  InjectsBaseUrl(@baseUrl this.url);
}

class XsrfToken extends OpaqueToken<String> {
  const XsrfToken();
}

@Injectable()
class InjectsXsrfToken {
  final String token;

  InjectsXsrfToken(@XsrfToken() this.token);
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

@GenerateInjector([
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
])
final InjectorFactory valueProviderExamples = ng.valueProviderExamples$Injector;

const duplicateToken = OpaqueToken<String>('duplicateToken');
const duplicateMulti = MultiToken<String>('duplicateMulti');

@GenerateInjector([
  ValueProvider.forToken(duplicateToken, 'A'),
  ValueProvider.forToken(duplicateToken, 'B'),
  ValueProvider.forToken(duplicateMulti, 'A'),
  ValueProvider.forToken(duplicateMulti, 'B'),
])
final InjectorFactory tokenOrdering = ng.tokenOrdering$Injector;

class ATypeThatShouldThrow {}

class _IntentionalError extends Error {}

class _CustomExceptionHandler implements ExceptionHandler {
  static Object? lastCaught;

  @override
  void call(exception, [stackTrace, String? reason]) {
    lastCaught = exception;
  }
}

class Place {
  final String name;

  Place(this.name);

  @override
  String toString() => '$Place {name=$name}';
}

@Injectable()
class Model {
  final Place place;

  Model(this.place);

  @override
  String toString() => '$Model {place=$place}';
}

@Component(
  selector: 'test',
  directives: [ProvidersDirective],
  template: '''
    <div providers>
      <span>Some content to create a range check on nodeIndex</span>
    </div>
    <div #container></div>
  ''',
)
class TestComponent {
  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef? viewContainerRef;
}

const testToken = OpaqueToken<String>('test');
const tokenA = OpaqueToken<String>('a');
const tokenB = OpaqueToken<String>('b');

@Directive(
  selector: '[providers]',
  // Multiple providers to ensure the range check isn't skipped due to short
  // circuit evaluation of mismatched token query.
  providers: [
    ValueProvider.forToken(tokenA, 'a'),
    ValueProvider.forToken(tokenB, 'b'),
  ],
)
class ProvidersDirective {}
