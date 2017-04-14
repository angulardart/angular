import 'dart:async';

import 'package:angular2/core.dart' show PLATFORM_INITIALIZER;
import 'package:angular2/di.dart' show Injector, provide, Provider;
import 'package:angular2/platform/testing/browser.dart';
import 'package:angular2/src/core/linker/app_view_utils.dart';
import 'package:angular2/src/core/reflection/reflection.dart';
import 'package:angular2/src/core/reflection/reflection_capabilities.dart';

import "internal_injector.dart";

export "package:angular2/src/debug/debug_node.dart";

export "fake_async.dart";
export "internal_injector.dart";
export "matchers.dart";
export "test_component_builder.dart";
export "utils.dart";

/// Allows injecting dependencies in [setUp()] and [test()].
///
/// Example:
///
///   test('...', inject([AClass], (object) => {
///     object.doSomething();
///     expect(...);
///   });
///
///   setUp(inject([Dependency, AClass], (dep, object) => {
///    // some code that uses `dep` and `object`
///    // ...
///   });
///
Future<dynamic> inject(List<dynamic> tokens, Function fn) async {
  _bootstrapInternalTests();
  _testInjector.reset();
  // Mark test as not async.
  AsyncTestCompleter.currentTestFuture = null;
  FunctionWithParamTokens funcWithParams = fn is FunctionWithParamTokens
      ? fn
      : new FunctionWithParamTokens(tokens, fn);
  if (funcWithParams.isAsync) {
    Provider p = provide(AsyncTestCompleter);
    assert(p != null);
    _testInjector.addProviders([funcWithParams.completer]);
  }
  if (_extraPerTestProviders != null) {
    if (_extraPerTestProviders != null)
      _testInjector.addProviders(_extraPerTestProviders);
  }
  _inTest = true;
  _testInjector
      .execute(new FunctionWithParamTokens([Injector], (Injector injector) {
    appViewUtils = injector.get(AppViewUtils);
  }));
  _testInjector.execute(funcWithParams);
  _inTest = false;
  if (AsyncTestCompleter.currentTestFuture != null) {
    await AsyncTestCompleter.currentTestFuture;
    return AsyncTestCompleter.currentTestFuture;
  }
}

/// Allows overriding default providers defined in test_injector.js.
///
///  The given function must return a list of DI providers.
///
///  Example:
///
///    beforeEachProviders(() => [
///        provide(Compiler, useClass: MockCompiler),
///        provide(SomeToken, useValue: myValue),
///    ]);
///
void beforeEachProviders(Function fn) {
  _extraPerTestProviders = fn();
}

TestInjector _testInjector = TestInjector.singleton();
bool _inTest = false;
// Set on one-time initialization of tests for platform.
bool _bootstrap_initialized = false;
// Providers for specific Platform.
List _platformProviders;
List _applicationProviders;
List _extraPerTestProviders;

void _bootstrapInternalTests() {
  _platformProviders ??= TEST_BROWSER_PLATFORM_PROVIDERS;
  _applicationProviders ??= TEST_BROWSER_APPLICATION_PROVIDERS;
  if (_bootstrap_initialized) return;
  _bootstrap_initialized = true;
  reflector.reflectionCapabilities = new ReflectionCapabilities();
  setBaseTestProviders(_platformProviders, _applicationProviders);
}

/// Set the providers that the test injector should use.
///
/// These should be providers common to every test in the suite.
void setBaseTestProviders(
    List<dynamic /* Type | Provider | List < dynamic > */ > platformProviders,
    List<dynamic /* Type | Provider | List < dynamic > */ >
        applicationProviders) {
  var testInjector = TestInjector.singleton();
  if (testInjector.platformProviders.length > 0 ||
      testInjector.applicationProviders.length > 0) {
    // This may only be called once, to set up the common providers for the
    // current test suite on the current platform.
    throw new StateError(
        'Cannot set base providers because it has already been called');
  }
  testInjector.platformProviders = platformProviders;
  testInjector.applicationProviders = applicationProviders;
  var injector = testInjector.createInjector();
  List<Function> initializers =
      injector.get(PLATFORM_INITIALIZER, null) as List<Function>;
  initializers?.forEach((init) => init());
  testInjector.reset();
}

TestInjector getTestInjector() => _testInjector;
