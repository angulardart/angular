import 'dart:async';
import 'dart:html';

import 'package:angular/core.dart';
import 'package:angular/src/bootstrap/modules.dart';
import 'package:angular/src/core/application_ref.dart';
import 'package:angular/src/core/linker.dart' show ComponentRef;
import 'package:angular/src/core/testability/testability.dart';
import 'package:angular/src/di/injector/runtime.dart';
import 'package:angular/src/platform/browser_common.dart';

export 'browser/tools/tools.dart' show enableDebugTools, disableDebugTools;

/// Bootstrapping for Angular applications.
///
/// You instantiate an Angular application by explicitly specifying a component
/// to use as the root component for your application via the [bootstrap]
/// method.
///
/// An application is bootstrapped inside an existing browser DOM, typically
/// `index.html`. Unlike Angular 1, Angular 2 does not compile/process providers
/// in index.html. This is mainly for security reasons, as well as architectural
/// changes in Angular 2. This means that `index.html` can safely be processed
/// using server-side technologies such as providers. Bindings can thus use
/// double-curly syntax, `{{...}}`, without collision with Angular 2
/// `{{...}}` template syntax.
///
/// When an app developer invokes [bootstrap] with a root component
/// as its argument, Angular performs the following tasks:
///
///  1. It uses the component's [selector] property to locate the DOM element
///     which needs to be upgraded into the angular component.
///  2. It creates a new child injector (from the platform injector).
///     Optionally, you can also override the injector configuration for an app
///     by invoking [bootstrap] with the [customProviders] argument.
///  3. It creates a new [Zone] and connects it to the angular application's
///     change detection domain instance.
///  4. It creates an emulated or shadow DOM on the selected component's host
///     element and loads the template into it.
///  5. It instantiates the specified component.
///  6. Finally, Angular performs change detection to apply the initial data
///     providers for the application.
///
/// ### Bootstrapping Multiple Applications
///
/// When working within a browser window, there are many singleton resources:
/// cookies, title, location, and others. Angular services that represent these
/// resources must likewise be shared across all Angular applications that
/// occupy the same browser window. For this reason, Angular creates exactly
/// one global platform object which stores all shared services, and each
/// angular application injector has the platform injector as its parent.
///
/// Each application has its own private injector as well. When there are
/// multiple applications on a page, Angular treats each application injector's
/// services as private to that application.
///
/// ### Examples
///
/// <?code-excerpt "docs/quickstart/web/main.dart"?>
/// ```dart
/// import 'package:angular/platform/browser.dart';
///
/// import 'package:angular_app/app_component.dart';
///
/// void main() {
///   bootstrap(AppComponent);
/// }
/// ```
///
/// <?code-excerpt "docs/toh-6/web/main.dart"?>
/// ```dart
/// import 'package:angular/angular.dart';
/// import 'package:angular/platform/browser.dart';
/// import 'package:angular_tour_of_heroes/app_component.dart';
/// import 'package:angular_tour_of_heroes/in_memory_data_service.dart';
/// import 'package:http/http.dart';
///
/// void main() {
///   bootstrap(AppComponent, [provide(Client, useClass: InMemoryDataService)]
///       // Using a real back end?
///       // Import browser_client.dart and change the above to:
///       // [provide(Client, useFactory: () => new BrowserClient(), deps: [])]
///       );
/// }
/// ```
///
/// For details concerning these examples see the
/// [Quickstart](https://webdev.dartlang.org/angular/quickstart) and
/// [Tour of Heroes Part 6][toh] documents, respectively.
///
/// [toh]: https://webdev.dartlang.org/angular/tutorial/toh-pt6
///
/// ### API
///
/// - [appComponentType]: The root component which should act as the
///   application. This is a reference to a [Type] which is annotated with
///   `@Component`.
/// - [customProviders]: An additional set of providers that can be added to the
///   app injector to override default injection behavior.
///
/// Returns a [Future] of [ComponentRef].
Future<ComponentRef<T>> bootstrap<T>(
  Type appComponentType, [
  List customProviders,
]) =>
    throw new UnsupportedError('''
Using the 'angular' transformer is required.

Please see https://webdev.dartlang.org/angular/tutorial for setup instructions,
and ensure your 'pubspec.yaml' file is configured to invoke the 'angular'
transformer on your application's entry point.''');

/// See [bootstrap] for more information.
Future<ComponentRef<T>> bootstrapStatic<T>(
  Type appComponentType, [
  List customProviders,
  Function initReflector,
]) {
  if (initReflector != null) {
    initReflector();
  }
  final appProviders = customProviders != null && customProviders.isNotEmpty
      ? [bootstrapLegacyModule, customProviders]
      : bootstrapLegacyModule;
  final platformRef = browserStaticPlatform();
  final appInjector = ReflectiveInjector.resolveAndCreate(
    appProviders,
    // ignore: argument_type_not_assignable
    platformRef.injector,
  );
  return coreLoadAndBootstrap<T>(appInjector, appComponentType);
}

HtmlDocument createDocument() => document;

PlatformRef browserStaticPlatform() {
  var platform = getPlatform();
  if (platform == null) {
    platform = new PlatformRefImpl();
    final testabilityRegistry = new TestabilityRegistry();
    createInitDomAdapter(testabilityRegistry)();
    createPlatform(new Injector.map({
      PlatformRef: platform,
      PlatformRefImpl: platform,
      TestabilityRegistry: testabilityRegistry,
    }));
  }
  return platform;
}
