library angular2_testing.angular2_testing;

import 'dart:async';

import 'package:angular2/angular2.dart';
import 'package:angular2/platform/testing/browser.dart';
import 'package:angular2/src/core/di/reflective_exceptions.dart'
    show NoAnnotationError;
import 'package:angular2/src/core/reflection/reflection.dart';
import 'package:angular2/src/core/reflection/reflection_capabilities.dart';
import 'package:angular2/src/testing/internal.dart'
    show
        TestComponentBuilder,
        ComponentFixture,
        setBaseTestProviders,
        getTestInjector,
        inject;
import 'package:test/test.dart';

import "internal_injector.dart";

export 'package:angular2/src/testing/internal.dart'
    show
        TestComponentBuilder,
        ComponentFixture,
        setBaseTestProviders,
        getTestInjector,
        inject;

/// One time initialization that must be done for Angular2 component
/// tests.
///
/// [initAngularTests] should be called before any test methods.
///
/// Example:
///
///     @TestOn('browser')
///     library mytestlibrary;
///
///     import 'package:angular2/angular2.dart';
///     import 'package:angular2/testing.dart';
///     import 'package:test/test.dart';
///
///     class SomeTestComponent {
///       String _value;
///       void init() {
///         _value = 'Hello';
///       }
///       String get value => _value;
///     }
///
///     main() {
///       initAngularTests();
///       group('SomeTestComponent', () {
///         setUpProviders(() => [SomeTestComponent]);
///         ngSetUp((SomeTestComponent component) {
///           component.init();
///         });
///         ngTest('test1', (SomeTestComponent component) {
///           expect(component.value, 'Hello');
///         });
///       });
///     }
///
void initAngularTests() {
  reflector.reflectionCapabilities = new ReflectionCapabilities();
  if (_testInjector == null) {
    setBaseTestProviders(
        TEST_BROWSER_PLATFORM_PROVIDERS, TEST_BROWSER_APPLICATION_PROVIDERS);
  }
}

void _addTestInjectorTearDown() {
  // Multiple resets are harmless.
  tearDown(() {
    _testInjector.reset();
  });
}

/// Allows overriding default bindings defined in test_injector.dart.
///
/// The given function must return a list of DI providers.
///
/// Example:
///
/// setUpProviders(() => [
///   provide(Compiler, useClass: MockCompiler),
///   provide(SomeToken, useValue: myValue),
/// ]);
///
void setUpProviders(List providerFactory()) {
  setUp(() {
    try {
      _testInjector.addProviders(providerFactory());
    } catch (e) {
      throw 'setUpProviders was called after the injector had '
          'been used in a setUp or test block. This invalidates the '
          'test injector';
    }
  });

  _addTestInjectorTearDown();
}

dynamic _runInjectableFunction(Function fn) {
  var params = reflector.parameters(fn);
  List<dynamic> tokens = <dynamic>[];
  for (var param in params) {
    var token;
    for (var paramMetadata in param) {
      if (paramMetadata is Type) {
        token = paramMetadata;
      } else if (paramMetadata is Inject) {
        token = paramMetadata.token;
      }
    }
    if (token == null) {
      throw new NoAnnotationError(fn, params);
    }
    tokens.add(token);
  }
  return new FunctionWithParamTokens(tokens, fn)
      .execute(_testInjector.createInjector());
}

/// Use the test injector to get bindings and run a function.
///
/// Example:
///
///     ngSetUp((SomeToken token) {
///       token.init();
///     });
///
void ngSetUp(Function fn) {
  setUp(() async {
    await _runInjectableFunction(fn);
  });

  _addTestInjectorTearDown();
}

/// Add a test which can use the test injector.
///
/// Example:
///
///     ngTest('description', (SomeToken token) {
///       expect(token, equals('expected'));
///     });
///
void ngTest(String description, Function fn,
    {String testOn, Timeout timeout, skip, Map<String, dynamic> onPlatform}) {
  test(description, () async {
    await _runInjectableFunction(fn);
  }, testOn: testOn, timeout: timeout, skip: skip, onPlatform: onPlatform);

  _addTestInjectorTearDown();
}

/// Add a test which creates an instance of a component.
void ngComponentTest(
    String description, Type componentType, fn(ComponentFixture fixture),
    {String templateOverride, List directives, List pipes, Function onError}) {
  test(description, () {
    return inject([TestComponentBuilder, AsyncTestCompleter],
        (TestComponentBuilder tcb, AsyncTestCompleter completer) {
      if (templateOverride != null) {
        return tcb
            .overrideView(
                componentType,
                new View(
                    template: templateOverride,
                    directives: directives,
                    pipes: pipes))
            .createAsync(componentType)
            .then((componentFixture) {
          var res = fn(componentFixture);
          if (res is Future) {
            res.then((_) {
              completer.done();
            });
          } else {
            completer.done();
          }
        }).catchError((e) {
          if (onError != null) {
            onError(e);
          } else {
            throw e;
          }
          completer.done();
        });
      } else {
        // Build component, call test case function without override.
        return tcb.createAsync(componentType).then((componentFixture) {
          var res = fn(componentFixture);
          if (res is Future) {
            res.then((_) {
              completer.done();
            });
          } else {
            completer.done();
          }
        }).catchError((e) {
          if (onError != null) {
            onError(e);
          } else {
            throw e;
          }
          completer.done();
        });
      }
    }).catchError((e) {
      if (onError != null) {
        onError(e);
      } else {
        throw e;
      }
    });
  });
}

final TestInjector _testInjector = getTestInjector();
