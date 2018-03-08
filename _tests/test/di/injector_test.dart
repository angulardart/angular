// ignore_for_file: invalid_use_of_protected_member
@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular/src/di/injector/hierarchical.dart';
import 'package:angular/src/di/injector/injector.dart';
import 'package:test/test.dart';
import 'package:angular/src/di/reflector.dart' as reflector;
import 'package:_tests/matchers.dart';

import 'injector_test.template.dart' as ng;

void main() {
  ng.initReflector();

  group('Injector', () {
    test('.get should delegate token to .inject', () {
      final injector = new CaptureInjectInjector();
      injector.get(ExampleService);
      expect(injector.lastToken, ExampleService);
      expect(injector.lastOrElse, throwIfNotFound);
    });

    group('.get should delegate', () {
      CaptureInjectInjector injector;

      setUp(() => injector = new CaptureInjectInjector());

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
      HierarchicalInjector i;

      test('should throw by default', () {
        i = new Injector.empty();
        expect(
          () => i.get(ExampleService),
          throwsNoProviderError,
        );
        expect(
          () => i.inject(ExampleService),
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
        final injector = new Injector.empty();
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
        final parent = new Injector.empty();
        final child = new Injector.empty(parent);
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
        i = new Injector.empty();
        expect(i.get(ExampleService, 123), 123);
        expect(i.injectOptional(ExampleService, 123), 123);
        expect(i.injectFromSelfOptional(ExampleService, 123), 123);
        expect(i.injectFromAncestryOptional(ExampleService, 123), 123);
        expect(i.injectFromParentOptional(ExampleService, 123), 123);
      });

      test('should fallback to the parent injector if provided', () {
        final parent = new Injector.map({ExampleService: 123});
        i = new Injector.empty(parent);
        expect(i.get(ExampleService), 123);
        expect(i.inject(ExampleService), 123);
        expect(
          () => i.injectFromSelf(ExampleService),
          throwsNoProviderError,
        );
        expect(i.injectFromAncestry(ExampleService), 123);
        expect(i.injectFromParent(ExampleService), 123);
      });

      test('should return itself if Injector is passed', () {
        i = new Injector.empty();
        expect(i.get(Injector), i);
      });
    });

    group('.map', () {
      HierarchicalInjector i;

      test('should return a provided key-value pair', () {
        i = new Injector.map({ExampleService: 123});
        expect(i.get(ExampleService), 123);
        expect(i.inject(ExampleService), 123);
        expect(i.injectFromSelf(ExampleService), 123);
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
        expect(i.get(Injector), i);
      });

      test('should throw a readable error message on a failure', () {
        final injector = new Injector.map({});
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

    group('.slowReflective', () {
      Injector i;

      setUpAll(() {
        reflector.registerFactory(ExampleService, () => new ExampleService());
        reflector.registerFactory(ExampleService2, () => new ExampleService2());
        reflector.registerDependencies(createListWith, [
          [String]
        ]);
      });

      test('should resolve a Type', () {
        i = ReflectiveInjector.resolveAndCreate([ExampleService]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService>());
      });

      test('should resolve a Provider', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(ExampleService),
        ]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService>());
      });

      test('should resolve a Provider.useClass', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(ExampleService, useClass: ExampleService2),
        ]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService2>());
      });

      test('should resolve a Provider.useValue', () {
        final serviceValue = new ExampleService();
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(ExampleService, useValue: serviceValue),
        ]);
        expect(i.get(ExampleService), serviceValue);
      });

      test('should resolve a Provider.useFactory', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(ExampleService, useFactory: createExampleService),
        ]);
        expect(i.get(ExampleService), const isInstanceOf<ExampleService>());
      });

      test('should resolve a Provider.useFactory with deps', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(String, useValue: 'Hello World'),
          new Provider(List, useFactory: createListWith),
        ]);
        expect(i.get(List), ['Hello World']);
      });

      test('should resolve a Provider.useFactory with manual deps', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(#fooBar, useValue: 'Hello World'),
          new Provider(List, useFactory: createListWith, deps: [#fooBar]),
        ]);
        expect(i.get(List), ['Hello World']);
      });

      test('should resolve a Provider.useExisting', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(ExampleService2),
          new Provider(ExampleService, useExisting: ExampleService2),
        ]);
        expect(i.get(ExampleService), i.get(ExampleService2));
      });

      test('should resolve a multi binding', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(#fooBar, useValue: 1, multi: true),
          new Provider(#fooBar, useValue: 2, multi: true),
        ]);
        expect(i.get(#fooBar), [1, 2]);
      });

      test('should resolve @Optional', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(List, useFactory: createListWithOptional),
        ]);
        expect(i.get(List), [null]);
      });

      test('should inject things in order of most-recently added', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(#a, useValue: 1),
          new Provider(#a, useValue: 2),
        ]);
        expect(i.get(#a), 2);
      });

      test('should return itself for "Injector"', () {
        i = ReflectiveInjector.resolveAndCreate([
          new Provider(#theInjector, useFactory: (i) => [i], deps: [Injector]),
        ]);
        expect(i.get(#theInjector), [i]);
      });

      test('should thrown when a provider was not found', () {
        i = ReflectiveInjector.resolveAndCreate([]);
        expect(() => i.get(#ABC), throwsNoProviderError);
      });

      test('should support resolveAndCreateChild', () {
        final oldC = new C('oldC');
        final parent = ReflectiveInjector.resolveAndCreate([
          A,
          B,
          new Provider(C, useValue: oldC),
        ]);
        final newC = new C('newC');
        final child1 = parent.resolveAndCreateChild([
          B,
          new Provider(C, useValue: newC),
        ]);
        final newB = child1.get(B);
        expect(newB.c, newC, reason: 'Expected a new "C" binding');
        final child2 = child1.resolveAndCreateChild([
          new Provider(B, useValue: newB),
        ]);
        final newA = child2.get(A);
        expect(newA.b, isNot(newB), reason: 'Expected an old "B" binding');
        expect(newA.b.c, oldC, reason: 'Expected an old "C" binding');
      });

      test('should reify a MultiProvider<T> in strong-mode runtimes', () {
        const usPresidents = const OpaqueToken<String>('usPresidents');
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider<String>(
            usPresidents,
            useValue: 'George W.',
            multi: true,
          ),
          const Provider<String>(
            usPresidents,
            useValue: 'Abraham L.',
            multi: true,
          ),
        ]);
        expect(injector.get(usPresidents), const isInstanceOf<List<String>>());
      });

      test('should support MultiToken instead of multi: true', () {
        const usPresidentsMulti = const MultiToken<String>('usPresidents');
        final injector = ReflectiveInjector.resolveAndCreate([
          const ValueProvider.forToken(usPresidentsMulti, 'George W.'),
          const ValueProvider.forToken(usPresidentsMulti, 'Abraham L.'),
        ]);
        expect(
          injector.get(usPresidentsMulti),
          const isInstanceOf<List<String>>(),
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
          const isInstanceOf<ExampleService>(),
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
          new Provider(
            ExampleService,
            useFactory: (Null willNeverBeCalled) => null,
            deps: const [ExampleService2],
          ),
        ]);
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.contains(''
                  'No provider found for $ExampleService2: '
                  '$ExampleService -> $ExampleService2.'),
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
          new Provider(
            ExampleService,
            useFactory: (Null willNeverBeCalled) => null,
            deps: const [ExampleService2],
          ),
          new Provider(
            ExampleService2,
            useFactory: (Null willNeverBeCalled) => null,
            deps: const [ExampleService3, ExampleService4],
          ),
          new Provider(
            ExampleService3,
            useValue: new ExampleService3(),
          ),
        ]);
        expect(
          () => injector.get(ExampleService),
          throwsA(
            predicate(
              (e) => '$e'.contains(''
                  'No provider found for $ExampleService4: '
                  '$ExampleService -> $ExampleService2 -> $ExampleService4.'),
            ),
          ),
        );
      });

      test('should treat an OpaqueToken identical to @Inject', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(baseUrl, useValue: 'https://site.com/api/'),
          InjectsBaseUrl,
        ]);
        final InjectsBaseUrl service = injector.get(InjectsBaseUrl);
        expect(service.url, 'https://site.com/api/');
      });

      test('should support a user type that extends OpaqueToken', () {
        final injector = ReflectiveInjector.resolveAndCreate([
          const Provider(const XsrfToken(), useValue: 'ABC123'),
          InjectsXsrfToken,
        ]);
        expect(injector.get(const XsrfToken()), 'ABC123');
        final InjectsXsrfToken service = injector.get(InjectsXsrfToken);
        expect(service.token, 'ABC123');
      });

      test('should support a Module class instead of a List', () {
        final injector = new Injector.slowReflective([
          const Module(
            include: const [
              const Module(
                provide: const [
                  const ValueProvider(ExampleService, const ExampleService()),
                ],
              ),
            ],
            provide: const [
              const ValueProvider(ExampleService2, const ExampleService2()),
              const ExistingProvider(ExampleService, ExampleService2),
            ],
          ),
        ]);
        expect(
          injector.get(ExampleService),
          const isInstanceOf<ExampleService2>(),
        );
      });
    });

    group('.generate', () {
      final injector = exampleGenerated();

      test('should consider Provider(T) as Provider(T, useClass: T)', () {
        expect(
          injector.get(ExampleService2),
          const isInstanceOf<ExampleService2>(),
        );
      });

      test('should support "useClass"', () {
        expect(
          injector.get(ExampleService),
          const isInstanceOf<ExampleService2>(),
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
          const isInstanceOf<List<String>>(),
          reason: 'A reified List<String> is expected',
        );
        expect(result, ['A', 'B']);
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
                  'No provider found for $MissingService: '
                  '$ExampleService3 -> $MissingService.'),
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
                  'No provider found for $MissingService: '
                  '$ExampleService4 -> $ExampleService3 -> $MissingService.'),
            ),
          ),
        );
      });

      test('should treat an OpaqueToken identical to @Inject', () {
        final InjectsBaseUrl service = injector.get(InjectsBaseUrl);
        expect(service.url, 'https://site.com/api/');
      });

      test('should support a user type that extends OpaqueToken', () {
        expect(injector.get(const XsrfToken()), 'ABC123');
        final InjectsXsrfToken service = injector.get(InjectsXsrfToken);
        expect(service.token, 'ABC123');
      });

      test('should support Module', () {
        expect(
          exampleFromModule().get(ExampleService),
          const isInstanceOf<ExampleService2>(),
        );
      });
    });
  });
}

/// Implementation of [Injector] that captures [lastToken] and [lastOrElse].
class CaptureInjectInjector extends Injector {
  Object lastToken;
  Object lastOrElse;

  @override
  T inject<T>(Object token) => injectOptional(token);

  @override
  Object injectOptional(Object token, [Object orElse]) {
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

const stringToken = const OpaqueToken('stringToken');
const numberToken = const OpaqueToken('numberToken');
const booleanToken = const OpaqueToken('booleanToken');
const simpleConstToken = const OpaqueToken('simpleConstToken');
const multiStringToken = const MultiToken<dynamic>('multiStringToken');

// We are going to expect these are different bindings.
const typedTokenOfDynamic = const OpaqueToken('typedToken');
const typedTokenOfString = const OpaqueToken<String>('typedToken');

const typedTokenOfListDynamic = const OpaqueToken<List>('typedToken');
const typedTokenOfListString = const OpaqueToken<List<String>>('typedToken');

const unnamedTokenOfDynamic = const OpaqueToken();
const unnamedTokenOfString = const OpaqueToken<String>();

Null willNeverBeCalled1(Object _) => null;
Null willNeverBeCalled2(Object _, Object __) => null;

@GenerateInjector(const [
  const Provider(ExampleService, useClass: ExampleService2),
  const Provider(ExampleService2),
  const Provider(stringToken, useValue: 'Hello World'),
  const Provider(numberToken, useValue: 1234),
  const Provider(booleanToken, useValue: true),
  const Provider(simpleConstToken, useValue: const ExampleService()),

  // Example of a runtime failure; MissingService
  const Provider(
    ExampleService3,
    useFactory: willNeverBeCalled1,
    deps: const [MissingService],
  ),

  // Example of a runtime failure; ExampleService3 -> MissingService.
  const Provider(
    ExampleService4,
    useFactory: willNeverBeCalled2,
    // Will find ExampleService2, ExampleService3 will fail (see above).
    deps: const [ExampleService2, ExampleService3],
  ),

  // TODO(matanl): Switch to ValueProvider.forToken once supported.
  const Provider<String>(multiStringToken, useValue: 'A'),
  const Provider<String>(multiStringToken, useValue: 'B'),

  // We are going to expect these are different bindings.
  const Provider(typedTokenOfDynamic, useValue: 1),
  const Provider(typedTokenOfString, useValue: 2),

  // We are going to expect these are also different bindings.
  const Provider(typedTokenOfListDynamic, useValue: 3),
  const Provider(typedTokenOfListString, useValue: 4),

  // We are going to expect these are also different bindings.
  const Provider(unnamedTokenOfDynamic, useValue: 5),
  const Provider(unnamedTokenOfString, useValue: 6),

  // Tests that @Inject(baseUrl) === @baseUrl
  const Provider(baseUrl, useValue: 'https://site.com/api/'),
  InjectsBaseUrl,

  // Tests that class T extends OpaqueToken
  const Provider(const XsrfToken(), useValue: 'ABC123'),
  InjectsXsrfToken,
])
final InjectorFactory exampleGenerated = ng.exampleGenerated$Injector;

@GenerateInjector.fromModules(const [
  const Module(
    include: const [
      const Module(
        provide: const [
          const ValueProvider(ExampleService, const ExampleService()),
        ],
      ),
    ],
    provide: const [
      const ValueProvider(ExampleService2, const ExampleService2()),
      const ExistingProvider(ExampleService, ExampleService2),
    ],
  ),
])
final InjectorFactory exampleFromModule = ng.exampleFromModule$Injector;

ExampleService createExampleService() => new ExampleService();
List createListWith(String item) => [item];

@Injectable()
List createListWithOptional(@Optional() String missing) => [missing];

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

const baseUrl = const OpaqueToken<String>('baseUrl');

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
