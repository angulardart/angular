// This is a transitional library that contains all of the top-level or static
// state that might be expected to move into "AppHost" after a refactor of the
// current APIs.

import 'package:angular/src/di/injector.dart';
import 'package:angular/src/testability.dart';

/// Maintains all top-level/static state for AngularDart apps.
///
/// This will eventually become `LegacyAppHost` once the final API is apparent.
class TransitionalAppHost {
  static Injector _createRootInjector() {
    // When it is possible to have conditional testability we will want to
    // refactor this code and/or make the root injector no longer necessary,
    // but that is a bigger breaking change.
    return Injector.map({
      TestabilityRegistry: TestabilityRegistry()..initializeEagerly(),
    });
  }

  TransitionalAppHost._();

  /// When creating new root injectors for an app, `hostInjector` is the parent.
  final _hostInjector = _createRootInjector();

  /// Creates a new [Injector] that lives underneath the root host injector.
  Injector createAppInjector(InjectorFactory create) {
    return create(_hostInjector);
  }
}

/// Top-levels and static state.
///
/// In the future this will be configurable once - ideally in a `main()` method.
final appGlobals = TransitionalAppHost._();
