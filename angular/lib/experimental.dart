/// A set of experimental APIs for AngularDart.
///
/// Internal APIs that are considered "public" for other packages to consume but
/// not for standard consumer use. For example, we might alter or remove any API
/// from this package at any time, without changing the version.
///
/// **Warning:** No API exposed as part of this package is considered stable.
@experimental
library angular.experimental;


import 'package:angular/angular.dart';
import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

import 'src/bootstrap/modules.dart';
import 'src/bootstrap/platform.dart';
import 'src/core/linker.dart' show ComponentFactory;
import 'src/core/linker/app_view.dart' as app_view;
import 'src/core/linker/app_view_utils.dart';
import 'src/di/reflector.dart' as reflector;

export 'src/bootstrap/modules.dart' show bootstrapLegacyModule;

/// Transitional API: Returns a [ComponentFactory] for [typeOrFactory].
///
/// If [typeOrFactory] is already a [ComponentFactory] this does nothing.
///
/// This API is slated for removal once the transition to factories is done.
@experimental
ComponentFactory<T> typeToFactory<T>(Object typeOrFactory) =>
    typeOrFactory is ComponentFactory<T>
        ? typeOrFactory
        : unsafeCast<ComponentFactory<T>>(
            reflector.getComponent(unsafeCast<Type>(typeOrFactory)));

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
  return createAppInjector(platformRef.injector);
}

/// Create a root minimal application (no runtime providers) injector.
///
/// Unlike [rootInjector], this method does not rely on `initReflector`.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
Injector rootMinimalInjector() => minimalApp(platformRef.injector);

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

/// Global platform reference.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
PlatformRef get platformRef => internalPlatform;
