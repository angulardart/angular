import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

import '../core/application_ref.dart';
import '../core/application_tokens.dart';
import '../core/di.dart' show ReflectiveInjector;
import '../core/linker.dart'
    show ComponentFactory, ComponentRef, SlowComponentLoader;
import '../core/linker/app_view_utils.dart';
import '../core/linker/component_resolver.dart' show typeToFactory;
import '../core/render/api.dart';
import '../core/testability/testability.dart';
import '../core/zone.dart';
import '../di/injector/empty.dart';
import '../di/injector/hierarchical.dart';
import '../di/injector/injector.dart';
import '../platform/browser_common.dart';
import '../platform/dom/events/event_manager.dart';
import '../platform/dom/shared_styles_host.dart';
import '../runtime.dart';
import '../security/dom_sanitization_service.dart';

import 'modules.dart';

Injector _platformInjectorCache;

/// **INTERNAL ONLY**: Creates a new injector for platform-level services.
Injector platformInjector() {
  if (_platformInjectorCache == null) {
    final testabilityRegistry = new TestabilityRegistry();
    sharedStylesHost ??= new DomSharedStylesHost(document);
    initTestability(testabilityRegistry);
    _platformInjectorCache = new Injector.map({
      TestabilityRegistry: testabilityRegistry,
    });
  }
  return _platformInjectorCache;
}

/// **INTERNAL ONLY**: Creates a new application-level Injector.
///
/// This is more complicated than just creating a new Injector, because we want
/// to make sure we allow [userProvidedInjector] to override _some_ top-level
/// services (`APP_ID`, `ExceptionHandler`) _and_ to ensure that Angular-level
/// services (`ApplicationRef`) get the user-provided versions.
Injector appInjector(InjectorFactory userProvidedInjector) {
  // These are the required root services, always provided by AngularDart.
  final Injector minimalInjector = minimalApp(platformInjector());

  // Lazily initialized later on once we have the user injector.
  ApplicationRef applicationRef;
  final Injector appGlobalInjector = new _LazyInjector({
    ApplicationRef: () => applicationRef,
    AppViewUtils: () => appViewUtils,
  }, unsafeCast(minimalInjector));

  // These are the user-provided overrides.
  final Injector userInjector = userProvidedInjector(appGlobalInjector);

  // Get a handle of NgZone, so we can create ApplicationRef in it.
  final NgZone ngZone = unsafeCast(minimalInjector.get(NgZone));

  // ... and then we add ApplicationRef, which has the unique property of
  // injecting services (specifically, `ExceptionHandler` and `APP_ID`) that
  // might have come from the user-provided injector, instead of the minimal.
  //
  // We also add other top-level services with similar constraints:
  // * `AppViewUtils`
  return ngZone.run(() {
    applicationRef = new ApplicationRefImpl(
      ngZone,
      userInjector,
    );
    appViewUtils = new AppViewUtils(
      unsafeCast(userInjector.get(APP_ID)),
      unsafeCast(userInjector.get(SanitizationService)),
      unsafeCast(minimalInjector.get(EventManager)),
    );
    return userInjector;
  });
}

/// An implementation of [Injector] that invokes closures.
///
/// ... right now this is a workaround for the ApplicationRef issue above.
///
/// TODO(matanl): Consider making this a user-accessible injector type.
@Immutable()
class _LazyInjector extends HierarchicalInjector {
  final Map<Object, Object Function()> _providers;

  const _LazyInjector(
    this._providers, [
    HierarchicalInjector parent = const EmptyInjector(),
  ]) : super(parent);

  @override
  Object injectFromSelfOptional(
    Object token, [
    Object orElse = throwIfNotFound,
  ]) {
    var result = _providers[token];
    if (result == null) {
      if (identical(token, Injector)) {
        return this;
      }
      return orElse;
    }
    return result();
  }
}

Injector _identityInjector([Injector parent]) => parent;

/// Starts a new AngularDart application with [componentFactory] as the root.
///
/// ```dart
/// // Assume this file is "main.dart".
/// import 'package:angular/angular.dart';
/// import 'main.template.dart' as ng;
///
/// @Component(
///   selector: 'hello-world',
///   template: '',
/// )
/// class HelloWorld {}
///
/// void main() {
///   runApp(ng.HelloWorldNgFactory);
/// }
/// ```
///
/// See [ComponentFactory] for documentation on how to find an instance of
/// a `ComponentFactory<T>` given a `class` [T] annotated with `@Component`. An
/// HTML tag matching the `selector` defined in [Component.selector] will be
/// upgraded to use AngularDart to manage that element (and its children). If
/// there is no matching element, a new tag will be appended to the `<body>`.
///
/// Optionally may supply a [createInjector] function in order to provide
/// services to the root of the application:
///
/// // Assume this file is "main.dart".
/// import 'package:angular/angular.dart';
/// import 'main.template.dart' as ng;
///
/// @Component(
///   selector: 'hello-world',
///   template: '',
/// )
/// class HelloWorld {
///   HelloWorld(HelloService service) {
///     service.sayHello();
///   }
/// }
///
/// class HelloService {
///   void sayHello() {
///     print('Hello World!');
///   }
/// }
///
/// void main() {
///   runApp(ng.HelloWorldNgFactory, createInjector: helloInjector);
/// }
///
/// @GenerateInjector(const [
///   const ClassProvider(HelloService),
/// ])
/// final InjectorFactory helloInjector = ng.helloInjector$Injector;
/// ```
///
/// See [InjectorFactory] for more examples.
///
/// Returns a [ComponentRef] with the created root component instance within the
/// context of a new [ApplicationRef], with change detection and other framework
/// internals setup.
ComponentRef<T> runApp<T>(
  ComponentFactory<T> componentFactory, {
  InjectorFactory createInjector: _identityInjector,
}) {
  if (isDevMode && componentFactory == null) {
    throw new ArgumentError.notNull('componentFactory');
  }
  final injector = appInjector(createInjector);
  final ApplicationRef appRef = unsafeCast(injector.get(ApplicationRef));
  return appRef.bootstrap(componentFactory);
}

/// Asynchronous alternative to [runApp], supporting [beforeComponentCreated].
///
/// The provided callback ([beforeComponentCreated]) is invoked _before_
/// creating the root component, with a handle to the root injector. The user
/// may choose to return a `Future` - it will be awaited before creating the
/// root component.
///
/// See [runApp] for additional details.
Future<ComponentRef<T>> runAppAsync<T>(
  ComponentFactory<T> componentFactory, {
  @required Future<void> Function(Injector) beforeComponentCreated,
  InjectorFactory createInjector: _identityInjector,
}) {
  if (isDevMode) {
    if (componentFactory == null) {
      throw new ArgumentError.notNull('componentFactory');
    }
    if (beforeComponentCreated == null) {
      throw new ArgumentError.notNull('beforeComponentCreated');
    }
  }
  final injector = appInjector(createInjector);
  return beforeComponentCreated(injector).then((_) {
    final appRef = unsafeCast<ApplicationRef>(injector.get(ApplicationRef));
    return appRef.bootstrap(componentFactory);
  });
}

/// Starts a new AngularDart application with [componentType] as the root.
///
/// This method is **soft deprecated**, and [runApp] is preferred as soon as
/// [initReflector] is no longer needed in your application. Specifically, using
/// this method enables the use of the following deprecated APIs:
/// * `ReflectiveInjector`
/// * `SlowComponentLoader`
///
/// ... if neither your app nor your dependencies requires these APIs, it is
/// recommended to switch to [runApp] instead, which has significant code-size
/// and startup time benefits.
ComponentRef<T> runAppLegacy<T>(
  Type componentType, {
  List<Object> createInjectorFromProviders: const [],
  void Function() initReflector,
}) {
  assert(T == dynamic || T == componentType, 'Expected $componentType == $T');
  if (initReflector != null) {
    initReflector();
  }
  if (isDevMode) {
    if (componentType == null) {
      throw new ArgumentError.notNull('componentType');
    }
    if (initReflector == null) {
      try {
        typeToFactory(componentType);
      } on StateError catch (_) {
        throw new ArgumentError(
          'Could not bootstrap $componentType: provide "initReflector".',
        );
      }
    }
  }
  return runApp(
    unsafeCast(typeToFactory(componentType)),
    createInjector: ([parent]) {
      return ReflectiveInjector.resolveAndCreate(
        [
          SlowComponentLoader,
          createInjectorFromProviders,
        ],
        unsafeCast(parent),
      );
    },
  );
}

/// Starts a new AngularDart application with [componentType] as the root.
///
/// This is the [runAppLegacy] variant of the [runAppAsync] function.
Future<ComponentRef<T>> runAppLegacyAsync<T>(
  Type componentType, {
  @required Future<void> Function(Injector) beforeComponentCreated,
  List<Object> createInjectorFromProviders: const [],
  void Function() initReflector,
}) {
  assert(T == dynamic || T == componentType, 'Expected $componentType == $T');
  if (initReflector != null) {
    initReflector();
  }
  if (isDevMode) {
    if (componentType == null) {
      throw new ArgumentError.notNull('componentType');
    }
    if (initReflector == null) {
      try {
        typeToFactory(componentType);
      } on StateError catch (_) {
        throw new ArgumentError(
          'Could not bootstrap $componentType: provide "initReflector".',
        );
      }
    }
  }
  return runAppAsync(
    unsafeCast(typeToFactory(componentType)),
    beforeComponentCreated: beforeComponentCreated,
    createInjector: ([parent]) {
      return ReflectiveInjector.resolveAndCreate(
        [
          SlowComponentLoader,
          createInjectorFromProviders,
        ],
        unsafeCast(parent),
      );
    },
  );
}

/// Starts a new AngularDart application with [componentType] as the root.
///
/// See [runAppLegacy] for the new name of this method.
@Deprecated('Renamed "runAppLegacy". See "runApp" for the preferred API.')
Future<ComponentRef<T>> bootstrapStatic<T>(
  Type componentType, [
  List<Object> providers = const [],
  void Function() initReflector,
]) =>
    new Future.microtask(
      () => runAppLegacy(
            componentType,
            createInjectorFromProviders: providers,
            initReflector: initReflector,
          ),
    );
