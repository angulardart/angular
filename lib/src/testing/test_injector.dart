import "package:angular2/core.dart"
    show ReflectiveInjector, PLATFORM_INITIALIZER;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

class TestInjector {
  bool _instantiated = false;
  ReflectiveInjector _injector = null;
  List<dynamic /* Type | Provider | List < dynamic > */ > _providers = [];
  reset() {
    this._injector = null;
    this._providers = [];
    this._instantiated = false;
  }

  List<dynamic /* Type | Provider | List < dynamic > */ > platformProviders =
      [];
  List<dynamic /* Type | Provider | List < dynamic > */ > applicationProviders =
      [];
  addProviders(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    if (this._instantiated) {
      throw new StateError(
          "Cannot add providers after test injector is instantiated");
    }
    this._providers = ListWrapper.concat(this._providers, providers);
  }

  createInjector() {
    var rootInjector =
        ReflectiveInjector.resolveAndCreate(this.platformProviders);
    this._injector = rootInjector.resolveAndCreateChild(
        ListWrapper.concat(this.applicationProviders, this._providers));
    this._instantiated = true;
    return this._injector;
  }

  dynamic execute(FunctionWithParamTokens fn) {
    var additionalProviders = fn.additionalProviders();
    if (additionalProviders.length > 0) {
      this.addProviders(additionalProviders);
    }
    if (!this._instantiated) {
      this.createInjector();
    }
    return fn.execute(this._injector);
  }
}

TestInjector _testInjector = null;
getTestInjector() {
  if (_testInjector == null) {
    _testInjector = new TestInjector();
  }
  return _testInjector;
}

/**
 * Set the providers that the test injector should use. These should be providers
 * common to every test in the suite.
 *
 * This may only be called once, to set up the common providers for the current test
 * suite on teh current platform. If you absolutely need to change the providers,
 * first use `resetBaseTestProviders`.
 *
 * Test Providers for individual platforms are available from
 * 'angular2/platform/testing/<platform_name>'.
 */
setBaseTestProviders(
    List<dynamic /* Type | Provider | List < dynamic > */ > platformProviders,
    List<
        dynamic /* Type | Provider | List < dynamic > */ > applicationProviders) {
  var testInjector = getTestInjector();
  if (testInjector.platformProviders.length > 0 ||
      testInjector.applicationProviders.length > 0) {
    throw new BaseException(
        "Cannot set base providers because it has already been called");
  }
  testInjector.platformProviders = platformProviders;
  testInjector.applicationProviders = applicationProviders;
  var injector = testInjector.createInjector();
  List<Function> initializers =
      injector.get(PLATFORM_INITIALIZER, null) as List<Function>;
  initializers?.forEach((init) => init());
  testInjector.reset();
}

/**
 * Reset the providers for the test injector.
 */
resetBaseTestProviders() {
  var testInjector = getTestInjector();
  testInjector.platformProviders = [];
  testInjector.applicationProviders = [];
  testInjector.reset();
}

/**
 * Allows injecting dependencies in `beforeEach()` and `it()`.
 *
 * Example:
 *
 * ```
 * beforeEach(inject([Dependency, AClass], (dep, object) => {
 *   // some code that uses `dep` and `object`
 *   // ...
 * }));
 *
 * it('...', inject([AClass], (object) => {
 *   object.doSomething();
 *   expect(...);
 * })
 * ```
 *
 * Notes:
 * - inject is currently a function because of some Traceur limitation the syntax should
 * eventually
 *   becomes `it('...', @Inject (object: AClass, async: AsyncTestCompleter) => { ... });`
 *
 * 
 * 
 * 
 */
FunctionWithParamTokens inject(List<dynamic> tokens, Function fn) {
  return new FunctionWithParamTokens(tokens, fn, false);
}

class InjectSetupWrapper {
  dynamic /* () => any */ _providers;
  InjectSetupWrapper(this._providers) {}
  FunctionWithParamTokens inject(List<dynamic> tokens, Function fn) {
    return new FunctionWithParamTokens(tokens, fn, false, this._providers);
  }

  /** @Deprecated {use async(withProviders().inject())} */
  FunctionWithParamTokens injectAsync(List<dynamic> tokens, Function fn) {
    return new FunctionWithParamTokens(tokens, fn, true, this._providers);
  }
}

withProviders(dynamic providers()) {
  return new InjectSetupWrapper(providers);
}

/**
 * @Deprecated {use async(inject())}
 *
 * Allows injecting dependencies in `beforeEach()` and `it()`. The test must return
 * a promise which will resolve when all asynchronous activity is complete.
 *
 * Example:
 *
 * ```
 * it('...', injectAsync([AClass], (object) => {
 *   return object.doSomething().then(() => {
 *     expect(...);
 *   });
 * })
 * ```
 *
 * 
 * 
 * 
 */
FunctionWithParamTokens injectAsync(List<dynamic> tokens, Function fn) {
  return new FunctionWithParamTokens(tokens, fn, true);
}

/**
 * Wraps a test function in an asynchronous test zone. The test will automatically
 * complete when all asynchronous calls within this zone are done. Can be used
 * to wrap an [inject] call.
 *
 * Example:
 *
 * ```
 * it('...', async(inject([AClass], (object) => {
 *   object.doSomething.then(() => {
 *     expect(...);
 *   })
 * });
 * ```
 */
FunctionWithParamTokens async(
    dynamic /* Function | FunctionWithParamTokens */ fn) {
  if (fn is FunctionWithParamTokens) {
    fn.isAsync = true;
    return fn;
  } else if (fn is Function) {
    return new FunctionWithParamTokens([], fn, true);
  } else {
    throw new BaseException(
        "argument to async must be a function or inject(<Function>)");
  }
}

List<dynamic> emptyArray() {
  return [];
}

class FunctionWithParamTokens {
  List<dynamic> _tokens;
  Function fn;
  bool isAsync;
  dynamic /* () => any */ additionalProviders;
  FunctionWithParamTokens(this._tokens, this.fn, this.isAsync,
      [this.additionalProviders = emptyArray]) {}

  /// Returns the value of the executed function.
  dynamic execute(ReflectiveInjector injector) {
    var params = this._tokens.map((t) => injector.get(t)).toList();
    return Function.apply(this.fn, params);
  }

  bool hasToken(dynamic token) {
    return this._tokens.indexOf(token) > -1;
  }
}
