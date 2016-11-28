import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/core/application_ref.dart';
import 'package:test/test.dart';

import 'errors.dart';
import 'ng_test_bootstrap.dart';
import 'ng_test_stabilizer.dart';

NgTestFixture _activeTest;

void _failIfTestRunning() {
  if (_activeTest != null) {
    fail('Another test is currently still live. NgTestBed support *one* test '
        'executing at a time in order to avoid timing conflicts or stability '
        'issues with applications sharing the browser DOM.\n\n'
        'When you are done with your test, make sure to "dipose" your '
        'NgTetsFixture, or for convenience use "disposeAnyRunningTest":\n\n'
        '   tearDown(() => disposeAnyRunningTest());\n\n'
        'Please note that this method returns a Future that must be completed '
        'before setting up another test ("tearDown" handles this for you if '
        'you return the future as seen above).');
  }
}

// Returns a new immutable list merging a and b.
List/*<E>*/ _concat/*<E>*/(Iterable/*<E>*/ a, Iterable/*<E>*/ b) =>
    new List/*<E>*/ .unmodifiable(/*<E>*/ new List/*<E>*/ .from(a)..addAll(b));

/// If any [NgTestController] is currently executing, calls [dispose] on it.
///
/// Returns a [Future] that completes when the test is destroyed.
///
/// This function is meant to be used within the
/// [`tearDown`](https://goo.gl/qT4fxc) function of `package:test`:
///     tearDown(() => disposeAnyRunningTest());
Future<Null> disposeAnyRunningTest() async {
  await _activeTest?.dispose();
  _activeTest = null;
}

/// An immutable builder for creating a pre-configured Angular application.
///
/// The root component type [T] that is created will build and work similarly
/// to how you would configure and run an application using `bootstrap` in
/// production.
///
/// For a simple test:
///     group('$HelloWorldComponent', () {
///       tearDown(() => disposeAnyRunningTest());
///
///       test('should render "Hello World", () async {
///         var bed = new NgTestBed<HelloWorldComponent>();
///         var fixture = await bed.create();
///         expect(fixture.text, contains('Hello World'));
///       });
///     });
///
/// New behavior and features can be added in a hierarchy of tests, such as:
///     group('My tests', () {
///       NgTestBed<HelloWorldComponent> bed;
///       NgTextFixture<HelloWorldComponent> fixture;
///
///       setUp(() => bed = new NgTestBed<HelloWorldComponent>());
///       tearDown(() => disposeAnyRunningTest());
///
///       test('should render "Hello World", () async {
///         fixture = await bed.create();
///         expect(fixture.text, contains('Hello World'));
///       });
///
///       test('should render "Hello World" in all-caps', () async {
///         bed = bed.addProviders(const [
///           const Provider(TextFormatter, useClass: AllCapsTextFormatter),
///         ]);
///         fixture = await bed.create();
///         expect(fixture.text, contains('HELLO WORLD'));
///       });
///     });
class NgTestBed<T> {
  static Element _createDefaultHost() {
    final host = new Element.tag('ng-test-bed');
    document.body.append(host);
    return host;
  }

  final Element _host;
  final List<Object> _providers;
  final List<RegisterStabilizer> _stabilizers;

  /// Create a new empty [NgTestBed].
  ///
  /// By default, stabilizers are added that understand the Angular lifecycle;
  /// they can be omitted by setting [watchAngularLifecycle] to false.
  factory NgTestBed({
    Element host,
    bool watchAngularLifecycle: true,
  }) {
    if (T == dynamic) {
      throw new GenericTypeRequiredError<NgTestBed>();
    }
    var bed = new NgTestBed<T>._();
    if (host != null) {
      bed = bed.setHost(host);
    }
    if (watchAngularLifecycle) {
      bed = bed.addStabilizers([
        new RegisterStabilizer<NgZoneStabilizer>(),
      ]);
    }
    return bed;
  }

  NgTestBed._([
    this._host,
    this._providers = const [],
    this._stabilizers = const [],
  ]) {
    // A factory should never invoke this constructor without T.
    assert(T != dynamic);
  }

  /// Creates a new instance of [NgTestBed] with [providers] added.
  ///
  /// If any element in [providers] is not an [Iterable], [Type], or [Provider]
  /// throws a [InvalidProviderTypeException] with details about the invalid
  /// element.
  ///
  /// __Example use__:
  ///     ngTestBed = ngTestBed.addProviders([
  ///       const Provider(Foo, useClass: StubFoo),
  ///     ])
  NgTestBed<T> addProviders(Iterable<Object> providers) {
    return fork(providers: _concat(_providers, providers));
  }

  /// Creates a new instance of [NgTestBed] with [stabilizers] added.
  ///
  /// __Example use__:
  ///     ngTestBed = ngTestBed.addStabilizers([
  ///       const RegisterStabilizer<NgZoneStabilizer>()
  ///     ])
  NgTestBed<T> addStabilizers(Iterable<RegisterStabilizer> stabilizers) {
    var types = stabilizers.map/*<Type>*/((s) => s.type);
    return fork(
      providers: _concat(_providers, types),
      stabilizers: _concat(_stabilizers, stabilizers),
    );
  }

  /// Create a new application with a root component.
  ///
  /// If [onLoad] is specified, is called back _before_ initialization.
  ///
  /// Returns a [Future] that completes with a created component.
  Future<NgTestFixture<T>> create({
    void onLoad(T instance),
  }) {
    // Purposefully does not use async/await, due to that starting an additional
    // microtask at the beginning. We want this assert to happen synchronously
    // to immediately catch an error.
    _failIfTestRunning();
    return new Future<NgTestFixture<T>>.sync(() {
      return ngTestBootstrap(
        T,
        _host ?? _createDefaultHost(),
        onLoad: onLoad,
        userProviders: _providers,
      ).then((componentRef) async {
        // Check one more time, because someone could have forgot to 'await'
        // this create statement and a test started since the last asynchronous
        // event.
        _failIfTestRunning();
        final stabilizer = new NgTestStabilizer.all(
          _stabilizers.map/*<NgTestStabilizer>*/(
            (s) => componentRef.injector.get(s.type),
          ),
        );
        final fixture = new NgTestFixture<T>._(
          componentRef.injector.get(ApplicationRef),
          componentRef,
          stabilizer,
        );
        return fixture;
      });
    });
  }

  /// Creates a new instance of [NgTestBed] with some properties changed.
  ///
  /// __Example use__:
  ///     ngTestBed = ngTestBed.fork(providers: [ ... ], stabilizers: [ ... ]);
  NgTestBed<T> fork({
    Element host,
    List<Object> providers,
    List<RegisterStabilizer> stabilizers,
  }) {
    return new NgTestBed<T>._(
      host ?? _host,
      providers ?? _providers,
      stabilizers ?? _stabilizers,
    );
  }

  /// Creates a new instance of [NgTestBed] with a new [host].
  NgTestBed<T> setHost(Element host) => fork(host: host);
}

/// Represents a running instance of Angular for a test case.
class NgTestFixture<T> {
  final ApplicationRef _applicationRef;
  final ComponentRef _componentRef;
  final NgTestStabilizer _stabilizer;

  NgTestFixture._(
    this._applicationRef,
    this._componentRef,
    this._stabilizer,
  ) {
    assert(T != dynamic);
  }

  /// Destroys the test case, returing a future that completes after disposed.
  ///
  /// In most cases, it is preferable to use [disposeAnyRunningTest].
  Future<Null> dispose() async {
    _componentRef.location.nativeElement.remove();
    _applicationRef.dispose();
  }

  /// Root DOM element of the test.
  Element get element => _componentRef.location.nativeElement;

  /// Returns a [Future] that completes after the DOM is reported stable.
  ///
  /// It is import to `update` before making an assertion on the DOM, as Angular
  /// (and other services) could be waiting (asynchronously) to make a change -
  /// and often you'd want to assert against the _final_ state.
  ///
  /// __Example use__:
  ///     expect(fixture.element.text, contains('Loading...'));
  ///     await fixture.update();
  ///     expect(fixture.element.text, contains('Hello World'));
  ///
  /// Optionally, pass a [fn] to run _before_ stabilizing:
  ///    await fixture.update((c) {
  ///      c.value = 5;
  ///    });
  ///    expect(fixture.element.text, contains('5 little piggues'));
  Future<Null> update([void fn(T instance)]) async {
    await _stabilizer.update(() {
      if (fn != null) {
        fn(_componentRef.instance);
      }
    });
  }
}
