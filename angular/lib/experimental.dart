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

import 'src/core/linker/app_view.dart' as app_view;
import 'src/core/linker/app_view_utils.dart';
import 'src/di/injector/injector.dart';

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
