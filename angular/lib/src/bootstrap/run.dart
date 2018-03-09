import 'dart:async';

import 'package:meta/meta.dart';

import '../core/application_ref.dart';
import '../core/linker.dart' show ComponentFactory, ComponentRef;
import '../core/linker/app_view_utils.dart';
import '../di/injector/hierarchical.dart';
import '../di/injector/injector.dart';
import '../di/injector/runtime.dart';
import '../di/reflector.dart' as reflector;
import '../runtime.dart';

import 'modules.dart';
import 'platform.dart';

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
/// ```
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
  var appInjector = minimalApp(internalPlatform.injector);
  if (createInjector != null) {
    appInjector = createInjector(appInjector);
  }
  final appRef = unsafeCast<ApplicationRef>(appInjector.get(ApplicationRef));
  appViewUtils = unsafeCast<AppViewUtils>(appInjector.get(AppViewUtils));
  return appRef.bootstrap(componentFactory, appInjector);
}

/// Starts a new AngularDart application in legacy mode, with [initReflector].
///
/// This method was formally known as `bootstrap` or `bootstrapStatic`, and
/// requires initializing a chain of generated `initReflector()` calls, starting
/// at the root:
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
///   runAppLegacy(HelloWorld, initReflector: ng.initReflector);
/// }
/// ```
///
/// You may pass either [rootProviders] or [createInjector] but not both in
/// order to configure root injectable services. The [createInjector] option
/// is available mainly as a transitional API to [runApp].
///
/// It is preferred to use [runApp] wherever possible, but note that the
/// following services are _not_ supported and require [runAppLegacy]:
/// * `APP_INITIALIZER`
/// * `ComponentResolver`
/// * `ReflectiveInjector`
/// * `SlowComponentLoader`
///
/// Returns a [ComponentRef] of [componentType].
Future<ComponentRef<T>> runAppLegacy<T>(
  Type componentType, {
  List<Object> rootProviders,
  InjectorFactory createInjector,
  @required void Function() initReflector,
}) {
  if (isDevMode && rootProviders != null && createInjector != null) {
    throw new ArgumentError('Specify either customProviders or createInjector');
  }
  final platformRef = internalPlatform;
  createInjector ??= ([injector]) {
    return ReflectiveInjector.resolveAndCreate(
      [rootProviders ?? [], bootstrapLegacyModule],
      unsafeCast<HierarchicalInjector>(injector),
    );
  };
  final appInjector = createInjector(platformRef.injector);
  final appRef = unsafeCast<ApplicationRef>(appInjector.get(ApplicationRef));
  appViewUtils = unsafeCast<AppViewUtils>(appInjector.get(AppViewUtils));
  return appRef.waitForAsyncInitializers().then((_) {
    return appRef.bootstrap(
      unsafeCast<ComponentFactory<T>>(reflector.getComponent(componentType)),
      appInjector,
    );
  });
}

const _errorMessage = 'Renamed "runAppLegacy". See doc comments for details';

/// See [runAppLegacy].
///
/// This method only worked in AngularDart 4.x and below, and relied on the
/// pub transformer automatically rewriting this function to [bootstrapStatic].
/// In AngularDart 5.x+, this rewrite should be done manually.
///
/// **BEFORE**:
/// ```
/// import 'package:angular/angular.dart';
///
/// void main() {
///   bootstrap(AppComponent, [providers]);
/// }
///
/// @Component(
///   selector: 'app',
///   template: 'Hello World',
/// )
/// class AppComponent {}
/// ```
///
/// **AFTER**:
/// ```
/// // assume this file is main.dart
/// import 'package:angular/angular.dart';
///
/// import 'main.template.dart' as ng;
///
/// void main() {
///   runAppLegacy(
///     AppComponent,
///     rootProviders: [providers],
///     initReflector: ng.initReflector,
///   );
/// }
/// ```
@Deprecated(_errorMessage)
@alwaysThrows
Future<ComponentRef<T>> bootstrap<T>(
  Type appComponentType, [
  List<Object> customProviders,
]) =>
    throw new UnsupportedError(_errorMessage);

/// See [runAppLegacy].
///
/// The API has changed slightly. Instead of:
/// ```
/// await bootstrapStatic(AppComponent, [providers], ng.initReflector);
/// ```
///
/// ... using [runAppLegacy]:
/// ```
/// runAppLegacy(
///   AppComponent,
///   customProviders: [providers],
///   initReflector: ng.initReflector,
/// );
/// ```
@Deprecated('Renamed "runAppLegacy"')
Future<ComponentRef<T>> bootstrapStatic<T>(
  Type componentType, [
  List<Object> rootProviders,
  void Function() initReflector,
]) =>
    new Future<ComponentRef<T>>.value(runAppLegacy(
      componentType,
      rootProviders: rootProviders,
      initReflector: initReflector,
    ));
