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
import 'package:angular/angular.dart';

import 'src/bootstrap/run.dart' show appInjector;
import 'src/runtime/dom_helpers.dart';

export 'src/common/directives/ng_for_identity.dart' show NgForIdentity;
export 'src/core/linker/component_factory.dart'
    show debugUsesDefaultChangeDetection;
export 'src/core/linker/component_resolver.dart' show typeToFactory;
export 'src/core/zone/ng_zone.dart' show longestPendingTimer, inAngularZone;
export 'src/meta.dart' show changeDetectionLink;

/// Create a root application [Injector].
///
/// Requires [userInjector] to provide app-level services or overrides:
/// ```dart
/// main() {
///   var injector = rootInjector((parent) {
///     return Injector.map({ /* ... */ }, parent);
///   });
/// }
/// ```
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
Injector rootInjector(InjectorFactory userInjector) {
  return appInjector(userInjector);
}

/// Returns `true` when AngularDart has modified the DOM.
///
/// May be used to optimize polling techniques that attempt to only process
/// events after a significant change detection cycle (i.e. one that modified
/// the DOM versus a no-op).
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
bool isDomRenderDirty() => domRootRendererIsDirty;

/// Resets the state of [isDomRenderDirty] to `false`.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
void resetDomRenderDirty() {
  domRootRendererIsDirty = false;
}
