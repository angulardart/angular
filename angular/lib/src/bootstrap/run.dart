import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';

import '../core/application_ref.dart';
import '../core/di.dart' show ReflectiveInjector;
import '../core/linker.dart'
    show ComponentFactory, ComponentRef, SlowComponentLoader;
import '../core/linker/app_view_utils.dart';
import '../core/linker/component_resolver.dart' show typeToFactory;
import '../core/render/api.dart';
import '../core/testability/testability.dart';
import '../di/injector/injector.dart';
import '../platform/browser_common.dart';
import '../platform/dom/shared_styles_host.dart';
import '../runtime.dart';

import 'modules.dart';

/// Creates a new injector for platform-level services.
Injector platformInjector() {
  final platformRef = new PlatformRefImpl();
  final testabilityRegistry = new TestabilityRegistry();
  sharedStylesHost ??= new DomSharedStylesHost(document);
  createInitDomAdapter(testabilityRegistry)();
  return new Injector.map({
    PlatformRef: platformRef,
    PlatformRefImpl: platformRef,
    TestabilityRegistry: testabilityRegistry,
  });
}

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
  InjectorFactory createInjector,
}) {
  if (isDevMode && componentFactory == null) {
    throw new ArgumentError.notNull('componentFactory');
  }
  var appInjector = minimalApp(platformInjector());
  if (createInjector != null) {
    appInjector = createInjector(appInjector);
  }
  _initializeGlobalState(appInjector);
  final appRef = unsafeCast<ApplicationRef>(appInjector.get(ApplicationRef));
  return appRef.bootstrap(componentFactory, appInjector);
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
  InjectorFactory createInjector,
}) {
  if (isDevMode) {
    if (componentFactory == null) {
      throw new ArgumentError.notNull('componentFactory');
    }
    if (beforeComponentCreated == null) {
      throw new ArgumentError.notNull('beforeComponentCreated');
    }
  }
  var appInjector = minimalApp(platformInjector());
  if (createInjector != null) {
    appInjector = createInjector(appInjector);
  }
  _initializeGlobalState(appInjector);
  return beforeComponentCreated(appInjector).then((_) {
    final appRef = unsafeCast<ApplicationRef>(appInjector.get(ApplicationRef));
    return appRef.bootstrap(componentFactory, appInjector);
  });
}

void _initializeGlobalState(Injector appInjector) {
  // Both of these global variables are expected to be set as part of the
  // bootstrap process. We should probably merge this concept with the platform
  // at some point.
  appViewUtils = unsafeCast<AppViewUtils>(appInjector.get(AppViewUtils));
  sharedStylesHost ??= new DomSharedStylesHost(document);
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
        [SlowComponentLoader, createInjectorFromProviders],
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
        [SlowComponentLoader, createInjectorFromProviders],
        unsafeCast(parent),
      );
    },
  );
}

// TODO: Remove once no internal users are referencing with 'hide bootstrap'.
void bootstrap(_, __) {}

/// Starts a new AngularDart application with [componentType] as the root.
///
/// See [runAppLegacy] for the new name of this method.
@Deprecated('Renamed "runAppLegacy". See "runApp" for the preferred API.')
Future<ComponentRef<T>> bootstrapStatic<T>(
  Type componentType, [
  List<Object> providers = const [],
  void Function() initReflector,
]) {
  return new Future.value(runAppLegacy(
    componentType,
    createInjectorFromProviders: providers,
    initReflector: initReflector,
  ));
}
