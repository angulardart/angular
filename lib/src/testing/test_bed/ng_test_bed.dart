import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';

import 'flatten_providers.dart';
import 'ng_dom_stabilizer.dart';
import 'test_injector.dart';

// Tracks the currently active test root to avoid multiple tests running.
NgTestRoot _activeTest;

/// An Angular Dart component test infrastructure for component [T].
///
/// An immutable data structure that returns a new instance of [NgTestBed] when
/// configuration is changed. This allows new behavior and features to be added
/// in a hierarchy of tests and setup, such as:
///    group('My tests', () {
///      NgTestBed<FooComponent> ngTestBed;
///
///      setUp(() => ngTestBed = new NgTestBed<FooComponent>());
///
///      test('should pass with no providers', () {
///        ...
///      });
///
///      test('should pass with a new provider', () {
///        ngTestBed = ngTestBed.addProviders([Foo]);
///        ...
///      });
///    });
class NgTestBed<T> {
  static void _assertNoTestRunning() {
    if (_activeTest != null) {
      throw new UnsupportedError(
          'Another test is currently still live. NgTestBed supports *one* test '
          'executing at a time in order to avoid timing conflicts or stability '
          'issues. When you are done with your test, make sure to "dispose" '
          'the root component. For example, using package:test:\n\n'
          '    tearDown(() => ngTestRoot.dispose());\n\n'
          'Please note that this method returns a Future that must be '
          'completed before setting up another test ("tearDown" handles this '
          'for you if you return the future as seen above).');
    }
  }

  // Root-level DI providers that are used when creating an Injector.
  final List<Object> _providers;

  // Types that implement NgDomStabilizer that are used to stabilize the DOM.
  final List<Type> _stabilizers;

  /// Create a new empty [NgTestBed].
  factory NgTestBed() {
    return new NgTestBed<T>._(<Provider>[], <Type>[]);
  }

  NgTestBed._(this._providers, this._stabilizers) {
    if (T == dynamic) {
      throw new UnsupportedError('Explicit component type T required.');
    }
  }

  /// Creates a new instance of [NgTestBed] with [providers] added.
  ///
  /// If any element in [providers] is not an [Iterable], [Type], or [Provider]
  /// throws a [InvalidProviderTypeException] with details about the invalid
  /// element.
  ///
  /// __Example use__:
  ///     ngTestBed = ngTestBed.addProviders([
  ///       const Provide(Foo, useClass: StubFoo),
  ///     ])
  NgTestBed<T> addProviders(Iterable<Object> providers) {
    return fork(
        providers: new List<Object>.unmodifiable(
            new List<Object>.from(_providers)
              ..addAll(flattenProviders(providers))));
  }

  /// Creates a new instance of [NgTestBed] with [stabilizers] added.
  ///
  /// __Example use__:
  ///     ngTestBed = ngTestBed.addStabilizers([
  ///       NgZoneStabilizer
  ///     ])
  NgTestBed<T> addStabilizers(Iterable<Type> stabilizers) {
    var flattenedProviders = new List<Object>.unmodifiable(
        new List<Object>.from(_providers)..addAll(stabilizers));
    var allStabilizers = new List<Type>.unmodifiable(
        new List<Type>.from(_stabilizers)..addAll(stabilizers));
    return fork(providers: flattenedProviders, stabilizers: allStabilizers);
  }

  /// Returns a [Future] that completes with a handle to a new test application.
  Future<NgTestRoot<T>> create() {
    // Purposefully does not use async/await, due to that starting an additional
    // microtask at the beginning. We want this assert to happen synchronously
    // to immediately catch an error.
    _assertNoTestRunning();
    var injector = new TestInjector(_providers);
    return injector.loadComponent(T).then((component) async {
      // Check one more time, because someone could have forgot to 'await' this
      // create statement and a test started since the last asynchronous event.
      _assertNoTestRunning();
      // The component should be given in an initialized state by default.
      var domStabilizer = new NgDomStabilizer.all(
          _stabilizers.map/*<NgDomStabilizer>*/(
              (s) => component.injector.get(s) as NgDomStabilizer));
      var root = _activeTest = new NgTestRoot<T>._(
        component,
        domStabilizer,
        injector,
      );
      await root.apply();
      return root;
    });
  }

  /// Creates a new instance of [NgTestBed] with some properties changed.
  ///
  /// __Example use__:
  ///     ngTestBed = ngTestBed.fork(providers: [ ... ]);
  NgTestBed<T> fork({List<Object> providers, List<Type> stabilizers}) {
    return new NgTestBed<T>._(
      providers ?? _providers,
      stabilizers ?? _stabilizers,
    );
  }
}

/// Disposes the currently active test, if any.
///
/// Exposed for testing use, but will not be exported in the public API.
Future<Null> disposeActiveTestIfAny() => _activeTest?.dispose();

/// Test application created by [NgTestBed].
///
/// A single [NgTestRoot] correlates to a running production application.
class NgTestRoot<T> {
  final ComponentRef _componentRef;
  final NgDomStabilizer _domStabilizer;
  final TestInjector _testInjector;

  // Avoids accidentally disposing a test multiple times.
  bool _wasDisposed = false;

  NgTestRoot._(this._componentRef, this._domStabilizer, this._testInjector);

  /// Returns a [Future] that completes when the DOM is likely stable.
  ///
  /// This may be used to wait before asserting the state of DOM, for example:
  ///     assertButton(ButtonElement button, NgTestRoot test) async {
  ///       expect(button.text, 'Yes');
  ///       await(test.apply(button.click));
  ///       expect(button.text, 'No');
  ///     }
  ///
  /// A [fn] may be supplied in order to run within the context of the test
  /// application, which may be necessary when changing the state or triggering
  /// callbacks that impact the Zone or other stabilization methods.
  ///
  /// See [NgDomStabilizer] for more details.
  Future<Null> apply([void fn()]) async {
    if (fn != null) {
      await _domStabilizer.execute(fn);
    } else {
      await _domStabilizer.stabilize();
    }
  }

  /// Returns a [Future] that completes when the application is destroyed.
  ///
  /// Should be either `await`ed or returned to a `tearDown` function before
  /// setting up another test to avoid timing conflicts.
  Future<Null> dispose() {
    // Purposefully avoids async/await, which adds a microtask before executing
    // this method. We want these state errors to trigger immediately.
    if (_wasDisposed) {
      throw new StateError('This test was already disposed!');
    }
    if (_activeTest != this) {
      throw new StateError('Invalid state: Another test is currently active.');
    }
    (_componentRef.location.nativeElement as Element).remove();
    _componentRef.destroy();
    _testInjector.dispose();
    _wasDisposed = true;
    _activeTest = null;
    return new Future<Null>.value();
  }
}
