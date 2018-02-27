import 'dart:html';

import '../core/application_ref.dart';
import '../core/linker.dart' show ComponentFactory, ComponentRef;
import '../core/linker/app_view_utils.dart';
import '../core/render/api.dart';
import '../di/injector/injector.dart';
import '../platform/dom/shared_styles_host.dart';
import '../runtime.dart';

import 'modules.dart';

/// Creates a new injector for platform-level services.
Injector _platformInjector() {
  final platformRef = new PlatformRefImpl();
  return new Injector.map({
    PlatformRef: platformRef,
    PlatformRefImpl: platformRef,
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
  if (isDevMode) {
    if (componentFactory == null) {
      throw new ArgumentError.notNull('componentFactory');
    }
  }
  var appInjector = minimalApp(_platformInjector());
  if (createInjector != null) {
    appInjector = createInjector(appInjector);
  }
  // Both of these global variables are spected to be set as part of the
  // bootstrap process. We should probably merge this concept with the platform
  // at some point.
  appViewUtils = unsafeCast<AppViewUtils>(appInjector.get(AppViewUtils));
  sharedStylesHost ??= new DomSharedStylesHost(document);
  final appRef = unsafeCast<ApplicationRef>(appInjector.get(ApplicationRef));
  return appRef.bootstrap(componentFactory, appInjector);
}
