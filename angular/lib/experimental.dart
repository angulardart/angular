/// A set of experimental APIs for AngularDart.
///
/// Internal APIs that are considered "public" for other packages to consume but
/// not for standard consumer use. For example, we might alter or remove any API
/// from this package at any time, without changing the version.
///
/// **Warning:** No API exposed as part of this package is considered stable.
@experimental
library angular.experimental;

import 'package:meta/meta.dart';

import 'src/bootstrap/modules.dart';
import 'src/core/application_ref.dart';
import 'src/core/linker.dart' show ComponentFactory, ComponentRef;
import 'src/core/linker/app_view.dart' as app_view;
import 'src/core/linker/app_view_utils.dart';
import 'src/di/injector/injector.dart';

export 'src/bootstrap/modules.dart' show bootstrapLegacyModule;

// Create a new injector for platform-level services.
//
// This injector is cached and re-used across every bootstrap(...) call.
final Injector _platformInjector = const Injector.empty(/*TODO: Implement.*/);

// Create a new injector for application-level (root) services.
//
// TODO(matanl): Convert this to a generated injector once available.
Injector _appInjector(Injector platform) => throw new UnimplementedError();

/// Bootstrap a new AngularDart application.
///
/// Uses a pre-compiled [factory] as the root component, instead of looking up
/// via [Type] at runtime, which requires `initReflector`. May optionally define
/// root-level services by providing a [createAppInjector].
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
ComponentRef<T> bootstrapFactory<T>(
  ComponentFactory<T> factory, [
  Injector createAppInjector(Injector parent),
]) {
  final appInjector = createAppInjector == null
      ? _appInjector(_platformInjector)
      : createAppInjector(_appInjector(_platformInjector));
  initAngular(appInjector);
  final appRef = appInjector.get(ApplicationRef) as ApplicationRef;
  return appRef.bootstrap(factory);
}

/// Bootstraps a new AngularDart application.
///
/// This is a transitional API to [bootstrapFactory] that removes some
/// `initReflector()`-based services from the initial bootstrap, but still
/// allows passing in [userProviders] at runtime.
///
/// It will be removed as soon as [bootstrapFactory] is better supported.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
ComponentRef<T> bootstrapMinimal<T>(
  ComponentFactory<T> factory,
  void initReflector(), [
  List<Object> userProviders = const [],
]) {
  // Still required, not ReflectiveInjector-free.
  initReflector();
  return bootstrapFactory(factory, (parent) {
    return new Injector.slowReflective([
      bootstrapMinimalModule,
      userProviders,
    ], parent);
  });
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
