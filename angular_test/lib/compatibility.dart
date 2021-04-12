/// Additional API to be used when migrating existing code to `angular_test`.
///
/// It is **highly recommended** not to use this and only stick to
/// `angular_test.dart` for any new code or for new users of this package. APIs
/// may change at _any time_ without adhering strictly to sem-ver.
@experimental
library angular_test.compatibility;

import 'package:meta/meta.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/bootstrap/run.dart' show appInjector;
import 'package:angular/src/core/linker/dynamic_component_loader.dart';

export 'src/frontend/bed.dart' show createDynamicFixture, createDynamicTestBed;
export 'src/frontend/fixture.dart' show injectFromFixture;

/// Creates an [Injector] similar to creating an application with [providers].
///
/// This function is intended to create a top-level injector that in turn can
/// be used to manually bootstrap a test. In practice, this is a highly non-
/// preferential code-path, because instead of using any of our built-in test
/// infrastructure you will need to create your own from nearly scratch.
///
/// In google3, this is used by the deprecated `useNgTestBed = false` path, in
/// which ACX creates its own test bed and stabilizers (and doesn't use our
/// `NgTestBed` code at all).
@experimental
Injector createTestInjector(List<Object> providers) {
  // This seems convoluted, but basically we want to create all of the core
  // Angular services first, and then provide this core service injector as the
  // parent to the user-supplied providers.
  return ReflectiveInjector.resolveAndCreate(
    providers,
    _rootLegacyInjector((parent) => parent),
  );
}

/// Create a root (legacy, with `SlowComponentLoader`) application [Injector].
///
/// Requires [userInjector] to provide app-level services or overrides:
/// ```dart
/// main() {
///   var injector = rootLegacyInjector((parent) {
///     return Injector.map({ /* ... */ }, parent);
///   });
/// }
/// ```
///
/// This method was moved from package:angular/experimental.dart after
/// [createTestInjector] became its sole remaining user.
Injector _rootLegacyInjector(InjectorFactory userInjector) {
  // Create a new appInjector, using wrappedUserInjector for provided services.
  // This includes services that will need to overwrite default services, such
  // as ExceptionHandler.
  return appInjector((parent) {
    return Injector.map({
      SlowComponentLoader: const SlowComponentLoader(
        ComponentLoader(),
      ),
    }, userInjector(parent));
  });
}
