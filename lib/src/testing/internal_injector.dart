import 'dart:async';

import 'package:angular2/di.dart' show ReflectiveInjector;

/// Provides reflective injector for executing a test.
class TestInjector {
  static TestInjector _testInjector;
  static TestInjector singleton() => (_testInjector ??= new TestInjector());

  bool _instantiated = false;
  ReflectiveInjector _injector;
  List<dynamic /* Type | Provider | List < dynamic > */ > _providers = [];
  void reset() {
    _injector = null;
    _providers = [];
    _instantiated = false;
  }

  List<dynamic /* Type | Provider | List < dynamic > */ > platformProviders =
      [];
  List<dynamic /* Type | Provider | List < dynamic > */ > applicationProviders =
      [];

  /// Adds custom providers to test injector.
  void addProviders(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    if (_instantiated) {
      throw new StateError(
          "Cannot add providers after test injector is instantiated");
    }
    _providers = []..addAll(_providers)..addAll(providers);
  }

  /// Creates injector with platform, application and custom providers.
  ReflectiveInjector createInjector() {
    var rootInjector =
        ReflectiveInjector.resolveAndCreate(this.platformProviders);
    _injector = rootInjector.resolveAndCreateChild(
        []..addAll(applicationProviders)..addAll(_providers));
    _instantiated = true;
    return _injector;
  }

  /// Executes wrapped test function using test injector.
  dynamic execute(FunctionWithParamTokens fn) {
    if (fn.additionalProviders != null) {
      var additionalProviders = fn.additionalProviders() as List;
      if (additionalProviders.length > 0) {
        this.addProviders(additionalProviders);
      }
    }
    if (!this._instantiated) {
      this.createInjector();
    }
    return fn.execute(this._injector);
  }
}

class FunctionWithParamTokens {
  List _tokens;
  Function fn;
  bool _isAsync = false;
  AsyncTestCompleter _completer;
  Function additionalProviders;

  FunctionWithParamTokens(this._tokens, this.fn, [this.additionalProviders]);

  /// Returns whether function injects AsyncTestCompleter.
  bool get isAsync => _isAsync;

  AsyncTestCompleter get completer => _completer;

  /// Runs the inner function with parameters provided by test injector.
  dynamic execute(ReflectiveInjector injector) {
    // For each parameter in function, get instance using injector and apply
    // to test function.
    var params = this._tokens.map((t) {
      if (t == AsyncTestCompleter) {
        _isAsync = true;
        return (_completer = new AsyncTestCompleter());
      }
      return injector.get(t);
    }).toList();
    return Function.apply(this.fn, params);
  }

  bool hasToken(dynamic token) {
    return this._tokens.indexOf(token) > -1;
  }
}

class AsyncTestCompleter {
  static Future currentTestFuture;

  final _completer = new Completer();

  AsyncTestCompleter() {
    currentTestFuture = this.future;
  }

  void done() {
    _completer.complete();
  }

  void resolve(value) {
    _completer.complete(value);
  }

  Future get future => _completer.future;
}
