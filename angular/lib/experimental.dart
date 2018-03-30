/// A set of experimental APIs for AngularDart.
///
/// Internal APIs that are considered "public" for other packages to consume but
/// not for standard consumer use. For example, we might alter or remove any API
/// from this package at any time, without changing the version.
///
/// **Warning:** No API exposed as part of this package is considered stable.
@experimental
library angular.experimental;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

import 'src/bootstrap/modules.dart';
import 'src/core/application_ref.dart';
import 'src/core/linker.dart' show ComponentFactory, ComponentRef;
import 'src/core/linker/app_view.dart' as app_view;
import 'src/core/linker/app_view_utils.dart';
import 'src/core/render/api.dart';
import 'src/di/injector/injector.dart';
import 'src/platform/bootstrap.dart';
import 'src/platform/dom/shared_styles_host.dart';

export 'src/bootstrap/modules.dart' show bootstrapLegacyModule;
export 'src/core/linker/component_resolver.dart' show typeToFactory;

// Create a new injector for platform-level services.
//
// This injector is cached and re-used across every bootstrap(...) call.
Injector _platformInjector() {
  final platformRef = new PlatformRefImpl();
  final throwingComponentLoader = new _ThrowingSlowComponentLoader();
  return new Injector.map({
    PlatformRef: platformRef,
    PlatformRefImpl: platformRef,
    SlowComponentLoader: throwingComponentLoader
  });
}

/// Bootstrap a new AngularDart application.
///
/// Uses a pre-compiled [factory] as the root component, instead of looking up
/// via [Type] at runtime, which requires `initReflector`. May optionally define
/// root-level services by providing a [createAppInjector].
///
/// **WARNING**: This API is not considered part of the stable API, and does
/// not support all of the features of the normal `bootstrap` process - namely
/// there is no support for `SlowComponentLoader`, `ReflectiveInjector` or
/// `TestabilityRegistry`.
@experimental
ComponentRef<T> bootstrapFactory<T>(
  ComponentFactory<T> factory, [
  InjectorFactory createAppInjector,
]) {
  final appInjector = createAppInjector == null
      ? minimalApp(_platformInjector())
      : createAppInjector(minimalApp(_platformInjector()));
  initAngular(appInjector);
  sharedStylesHost ??= new DomSharedStylesHost(document);
  final appRef = appInjector.get(ApplicationRef) as ApplicationRef;
  return appRef.bootstrap(factory, appInjector);
}

/// Creates a root application injector by invoking [createAppInjector].
///
/// ```dart
/// main() {
///   var injector = rootLegacyInjector((parent) {
///     return new Injector.map({ /* ... */ }, parent);
///   });
/// }
/// ```
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
Injector rootInjector(Injector createAppInjector(Injector parent)) {
  // TODO(matanl): Use a generated injector once the API is stable.
  return createAppInjector(browserStaticPlatform().injector);
}

/// Create a root minimal application (no runtime providers) injector.
///
/// Unlike [rootInjector], this method does not rely on `initReflector`.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
Injector rootMinimalInjector() => minimalApp(_platformInjector());

/// Initializes the global application state from an application [injector].
///
/// May be used in places that do not go through `bootstrap` to create an
/// application, but do not want to import parts of Angular's internal API to
/// get to a valid state.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
void initAngular(Injector injector) {
  appViewUtils = unsafeCast<AppViewUtils>(injector.get(AppViewUtils));
}

/// Returns `true` when AngularDart has modified the DOM.
///
/// May be used to optimize polling techniques that attempt to only process
/// events after a significant change detection cycle (i.e. one that modified
/// the DOM versus a no-op).
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
bool isDomRenderDirty() => app_view.domRootRendererIsDirty;

/// Resets the state of [isDomRenderDirty] to `false`.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
void resetDomRenderDirty() {
  app_view.domRootRendererIsDirty = false;
}

/// Implementation of [SlowComponentLoader] that throws an UnimplementedError
/// when used.
///
/// This is to allow a migration path for common components that may need to
/// inject [SlowComponentLoader] for the legacy `bootstrapStatic` method, but
/// won't actually use it in apps that called `bootstrapFactory`.
class _ThrowingSlowComponentLoader implements SlowComponentLoader {
  @override
  Future<ComponentRef<T>> load<T>(Type type, Injector injector) {
    throw new UnimplementedError(_slowComponentLoaderWarning);
  }

  @override
  Future<ComponentRef<T>> loadNextToLocation<T>(
      Type type, ViewContainerRef location,
      [Injector injector]) {
    throw new UnimplementedError(_slowComponentLoaderWarning);
  }
}

const _slowComponentLoaderWarning = 'You are using bootstrapFactory, which no '
    'longer supports loading a component with SlowComponentLoader. Please '
    'migrate this code to use ComponentLoader instead.';
