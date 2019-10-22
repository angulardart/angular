// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';
import 'package:angular/experimental.dart';

import '../bootstrap.dart';
import '../errors.dart';
import 'fixture.dart';
import 'ng_zone/real_time_stabilizer.dart';
import 'ng_zone/timer_hook_zone.dart';
import 'stabilizer.dart';

/// Used to determine if there is an actively executing test.
NgTestFixture<Object> activeTest;

/// If any [NgTestFixture] is currently executing, calls `dispose` on it.
///
/// Returns a future that completes when the test is destroyed.
///
/// This function is meant to be used within the
/// [`tearDown`](https://goo.gl/qT4fxc) function of `package:test`:
/// ```dart
/// tearDown(() => disposeAnyRunningTest());
/// ```
Future<void> disposeAnyRunningTest() async => activeTest?.dispose();

/// An alternative method for [NgTestBed.create] that allows a dynamic [type].
///
/// This is for compatibility reasons only and should not be used otherwise.
Future<NgTestFixture<T>> createDynamicFixture<T>(
  NgTestBed<T> bed,
  Type type, {
  FutureOr<void> Function(Injector) beforeComponentCreated,
  FutureOr<void> Function(T) beforeChangeDetection,
}) {
  return bed._createDynamic(type,
      beforeComponentCreated: beforeComponentCreated,
      beforeChangeDetection: beforeChangeDetection);
}

/// An alternative factory for [NgTestBed] that allows not typing `T`.
///
/// This is for compatibility reasons only and should not be used otherwise.
NgTestBed<T> createDynamicTestBed<T>({
  Element host,
  InjectorFactory rootInjector,
  bool watchAngularLifecycle = true,
}) {
  return NgTestBed<T>._allowDynamicType(
    host: host,
    rootInjector: rootInjector,
    watchAngularLifecycle: watchAngularLifecycle,
  );
}

/// An immutable builder for creating a pre-configured AngularDart application.
///
/// The root component type [T] that is created is essentially the same as a
/// root application component you would create normally with `bootstrap`.
///
/// For a simple test:
/// ```dart
/// group('$HelloWorldComponent', () {
///   tearDown(() => disposeAnyRunningTest());
///
///   test('should render "Hello World"', () async {
///     var bed = new NgTestBed<HelloWorldComponent>();
///     var fixture = await bed.create();
///     expect(fixture.text, contains('Hello World'));
///   });
/// });
/// ```
///
/// New behavior and features can be added in a hierarchy of tests:
/// ```dart
/// group('My tests', () {
///   NgTestBed<HelloWorldComponent> bed;
///   NgTestFixture<HelloWorldComponent> fixture;
///
///   setUp(() => bed = new NgTestBed<HelloWorldComponent>());
///   tearDown(() => disposeAnyRunningTest());
///
///   test('should render "Hello World", () async {
///     fixture = await bed.create();
///     expect(fixture.text, contains('Hello World'));
///   });
///
///   test('should render "Hello World" in all-caps', () async {
///     bed = bed.addProviders(const [
///       const Provider(TextFormatter, useClass: AllCapsTextFormatter),
///     ]);
///     fixture = await bed.create();
///     expect(fixture.text, contains('HELLO WORLD'));
///   });
/// });
/// ```
class NgTestBed<T> {
  static Element _defaultHost() {
    final host = Element.tag('ng-test-bed');
    document.body.append(host);
    return host;
  }

  static Injector _defaultRootInjector([Injector parent]) {
    return Injector.empty(parent);
  }

  static NgTestStabilizer _alwaysStable(_) => NgTestStabilizer.alwaysStable;

  static NgTestStabilizer _defaultStabilizers(
    Injector injector, [
    TimerHookZone timerZone,
  ]) {
    return RealTimeNgZoneStabilizer(timerZone, injector.provideType(NgZone));
  }

  final Element _host;
  final List<Object> _providers;
  final NgTestStabilizerFactory _createStabilizer;

  // Used only with .forComponent:
  final ComponentFactory<T> _componentFactory;
  final InjectorFactory _rootInjector;

  /// Create a new [NgTestBed] that uses the provided [component] factory.
  ///
  /// There are some differences between this API and the normal [NgTestBed]:
  /// * [addProviders] will throw [UnsupportedError]; instead, the [addInjector]
  ///   API allows you to wrap the previous [Injector], if any, to provide
  ///   additional services. In most cases just [rootInjector] is enough, and
  ///   you could re-use providers via [GenerateInjector].
  ///
  /// ```dart
  /// main() {
  ///   final ngTestBed = NgTestBed.forComponent(
  ///     SomeComponentNgFactory,
  ///     rootInjector: ([parent]) => new Injector.map({
  ///       Service: new Service(),
  ///     }, parent),
  ///   );
  /// }
  /// ```
  ///
  /// **NOTE**: This is the only way to use [NgTestBed] without requiring use
  /// of the `initReflector()` API on startup.
  static NgTestBed<T> forComponent<T>(
    ComponentFactory<T> component, {
    Element host,
    InjectorFactory rootInjector = _defaultRootInjector,
    bool watchAngularLifecycle = true,
  }) {
    if (T == dynamic) {
      throw GenericTypeMissingError();
    }
    if (component == null) {
      throw ArgumentError.notNull('component');
    }
    return NgTestBed<T>._useComponentFactory(
      component: component,
      rootInjector: rootInjector,
      host: host,
      watchAngularLifecycle: watchAngularLifecycle,
    );
  }

  /// Create a new empty [NgTestBed] that creates a component type [T].
  ///
  /// May optionally specify what DOM element should [host] the component.
  ///
  /// By default, the resulting [NgTestFixture] automatically waits for Angular
  /// to signal completion of change detection - this behavior can vbe disabled
  /// by setting [watchAngularLifecycle] to `false`.
  factory NgTestBed({
    Element host,
    InjectorFactory rootInjector,
    bool watchAngularLifecycle = true,
  }) {
    if (T == dynamic) {
      throw GenericTypeMissingError();
    }
    return NgTestBed<T>._allowDynamicType(
      host: host,
      rootInjector: rootInjector,
      watchAngularLifecycle: watchAngularLifecycle,
    );
  }

  // Used for compatibility only.
  factory NgTestBed._allowDynamicType({
    Element host,
    InjectorFactory rootInjector,
    bool watchAngularLifecycle = true,
  }) {
    return NgTestBed<T>._(
      host: host,
      // For uses of NgTestBed w/o `.forComponent`, we enable legacy APIs.
      providers: const [SlowComponentLoader], // ignore: deprecated_member_use
      stabilizer: watchAngularLifecycle ? _defaultStabilizers : _alwaysStable,
      rootInjector: rootInjector,
    );
  }

  NgTestBed._({
    Element host,
    Iterable<Object> providers,
    NgTestStabilizerFactory stabilizer,
    InjectorFactory rootInjector,
    ComponentFactory<T> component,
  })  : _host = host,
        _providers = providers.toList(),
        _createStabilizer = stabilizer,
        _rootInjector = rootInjector ?? _defaultRootInjector,
        _componentFactory = component;

  NgTestBed._useComponentFactory({
    @required Element host,
    @required ComponentFactory<T> component,
    @required InjectorFactory rootInjector,
    @required bool watchAngularLifecycle,
  })  : _host = host,
        _providers = const [],
        _createStabilizer =
            watchAngularLifecycle ? _defaultStabilizers : _alwaysStable,
        _rootInjector = rootInjector,
        _componentFactory = component;

  /// Whether this is the new-style [ComponentFactory]-backed [NgTestBed].
  bool get _usesComponentFactory => _componentFactory != null;

  /// Returns a new instance of [NgTestBed] with [providers] added.
  NgTestBed<T> addProviders(Iterable<Object> providers) {
    if (_usesComponentFactory) {
      throw UnsupportedError('Use "addInjector" instead');
    }
    return fork(providers: [..._providers, ...providers]);
  }

  /// Returns a new instance of [NgTestBed] with the root injector wrapped.
  ///
  /// That is, [factory] will _supplement_ the existing injector(s). In most
  /// cases this is likely not required unless you are re-using test
  /// configuration across many tests with subtle differences.
  NgTestBed<T> addInjector(InjectorFactory factory) {
    return fork(
      rootInjector: ([Injector parent]) => _rootInjector(factory(parent)),
    );
  }

  /// Returns a new instance of [NgTestBed] with [stabilizers] added.
  NgTestBed<T> addStabilizers(Iterable<NgTestStabilizerFactory> stabilizers) {
    return fork(
      stabilizer: composeStabilizers([_createStabilizer, ...stabilizers]),
    );
  }

  /// Creates a new test application with [T] as the root component.
  ///
  /// If [beforeChangeDetection] is set, it is called _before_ any initial
  /// change detection (so you can do initialization of component state that
  /// might be required).
  ///
  /// Returns a future that completes with a fixture around the component.
  Future<NgTestFixture<T>> create({
    FutureOr<void> Function(Injector) beforeComponentCreated,
    FutureOr<void> Function(T instance) beforeChangeDetection,
  }) {
    return _createDynamic(
      T,
      beforeComponentCreated: beforeComponentCreated,
      beforeChangeDetection: beforeChangeDetection,
    );
  }

  static void _checkForActiveTest() {
    if (activeTest != null) {
      throw TestAlreadyRunningError();
    }
  }

  /// Creates the root [InjectorFactory] for a test instance.
  InjectorFactory _createRootInjectorFactory() {
    var rootInjector = _rootInjector;
    if (_providers.isNotEmpty) {
      rootInjector = ([parent]) {
        return ReflectiveInjector.resolveAndCreate(
          _providers,
          _rootInjector(parent),
        );
      };
    }
    return rootInjector;
  }

  // Used for compatibility only. See `create` for public API.
  Future<NgTestFixture<T>> _createDynamic(
    Type type, {
    FutureOr<void> Function(Injector) beforeComponentCreated,
    FutureOr<void> Function(T instance) beforeChangeDetection,
  }) {
    // We *purposefully* do not use async/await here - that always adds an
    // additional micro-task - we want this to fail fast without entering an
    // asynchronous event if another test is running.
    _checkForActiveTest();

    // Future.sync promotes synchronous errors to Future.error if they occur.
    return Future<NgTestFixture<T>>.sync(() {
      // Ensure that no tests have started since the last microtask.
      _checkForActiveTest();

      // Create a zone to intercept timer creation.
      final timerHookZone = TimerHookZone();
      NgZone ngZoneInstance;
      NgZone ngZoneFactory() {
        return timerHookZone.run(() {
          return ngZoneInstance = NgZone();
        });
      }

      // Created within "createStabilizersAndRunUserHook".
      NgTestStabilizer allStabilizers;

      Future<void> createStabilizersAndRunUserHook(Injector injector) async {
        // Some internal stabilizers get access to the TimerHookZone.
        // Most (i.e. user-land) stabilizers do not.
        final createStabilizer = _createStabilizer;
        allStabilizers = createStabilizer is AllowTimerHookZoneAccess
            ? createStabilizer(injector, timerHookZone)
            : createStabilizer(injector);

        // If there is no user hook, we are done.
        if (beforeComponentCreated == null) {
          return null;
        }

        // If there is a user hook, execute it within the ngZone:
        final completer = Completer<void>();
        ngZoneInstance.runGuarded(() async {
          try {
            await beforeComponentCreated(injector);
            completer.complete();
          } catch (e, s) {
            completer.completeError(e, s);
          }
        });
        return completer.future.whenComplete(() => allStabilizers.update());
      }

      return bootstrapForTest<T>(
        _componentFactory ?? typeToFactory(type),
        _host ?? _defaultHost(),
        _createRootInjectorFactory(),
        beforeComponentCreated: createStabilizersAndRunUserHook,
        beforeChangeDetection: beforeChangeDetection,
        createNgZone: ngZoneFactory,
      ).then((componentRef) async {
        _checkForActiveTest();
        await allStabilizers.stabilize();
        final testFixture = NgTestFixture(
          componentRef.injector.get(ApplicationRef),
          componentRef,
          allStabilizers,
        );
        // We need the local variable to capture the generic type T.
        activeTest = testFixture;
        return testFixture;
      });
    });
  }

  /// Creates a new instance of [NgTestBed].
  ///
  /// Any non-null value overrides the existing properties.
  NgTestBed<E> fork<E extends T>({
    Element host,
    ComponentFactory<E> component,
    Iterable<Object> providers,
    InjectorFactory rootInjector,
    NgTestStabilizerFactory stabilizer,
  }) {
    return NgTestBed<E>._(
      host: host ?? _host,
      providers: providers ?? _providers,
      stabilizer: stabilizer ?? _createStabilizer,
      rootInjector: rootInjector ?? _rootInjector,
      component: component ?? _componentFactory,
    );
  }

  /// Returns a new instance of [NgTestBed] with [component] overrode.
  NgTestBed<E> setComponent<E extends T>(ComponentFactory<E> component) {
    return fork(component: component);
  }

  /// Returns a new instance of [NgTestBed] with [host] overrode.
  NgTestBed<T> setHost(Element host) => fork(host: host);
}
