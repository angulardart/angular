/// A set of experimental APIs for AngularDart.
///
/// Internal APIs that are considered "public" for other packages to consume but
/// not for standard consumer use. For example, we might alter or remove any API
/// from this package at any time, without changing the version.
///
/// **Warning:** No API exposed as part of this package is considered stable.
@experimental
library angular.experimental;

import 'dart:html';

import 'package:meta/meta.dart';

import 'src/bootstrap/modules.dart';
import 'src/core/application_ref.dart';
import 'src/core/linker.dart' show ComponentFactory, ComponentRef;
import 'src/core/linker/app_view.dart' as app_view;
import 'src/core/linker/app_view_utils.dart';
import 'src/core/render/api.dart';
import 'src/di/injector/injector.dart';
import 'src/di/reflector.dart' as reflector;
import 'src/platform/bootstrap.dart';
import 'src/platform/dom/shared_styles_host.dart';

export 'src/bootstrap/modules.dart' show bootstrapLegacyModule;

// Create a new injector for platform-level services.
//
// This injector is cached and re-used across every bootstrap(...) call.
Injector _platformInjector() {
  final platformRef = new PlatformRefImpl();
  return new Injector.map({
    PlatformRef: platformRef,
    PlatformRefImpl: platformRef,
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
  Injector createAppInjector(Injector parent),
]) {
  final appInjector = createAppInjector == null
      ? minimalApp(_platformInjector())
      : createAppInjector(minimalApp(_platformInjector()));
  initAngular(appInjector);
  sharedStylesHost ??= new DomSharedStylesHost(document);
  final appRef = appInjector.get(ApplicationRef) as ApplicationRef;
  return appRef.bootstrap(factory, appInjector);
}

/// Transitional API: Returns a [ComponentFactory] for [typeOrFactory].
///
/// If [typeOrFactory] is already a [ComponentFactory] this does nothing.
///
/// This API is slated for removal once the transition to factories is done.
@experimental
ComponentFactory<T> typeToFactory<T>(Object typeOrFactory) =>
    typeOrFactory is ComponentFactory<T>
        ? typeOrFactory
        : reflector.getComponent(typeOrFactory);

/// Creates a root application injector by invoking [createAppInjector].
///
/// ```dart
/// main() {
///   var injector = rootInjector((parent) {
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

/// Initializes the global application state from an application [injector].
///
/// May be used in places that do not go through `bootstrap` to create an
/// application, but do not want to import parts of Angular's internal API to
/// get to a valid state.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
void initAngular(Injector injector) {
  appViewUtils = injector.get(AppViewUtils);
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
