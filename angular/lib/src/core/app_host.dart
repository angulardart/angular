// This is a transitional library that contains all of the top-level or static
// state that might be expected to move into "AppHost" after a refactor of the
// current APIs.

import 'package:angular/src/core/di.dart';
import 'package:angular/src/core/testability/testability.dart';
import 'package:angular/src/platform/browser/testability.dart';

/// Maintains all top-level/static state for AngularDart apps.
///
/// This will eventually become `LegacyAppHost` once the final API is apparent.
class TransitionalAppHost {
  static Injector _createRootInjector() {
    final registry = TestabilityRegistry();
    registry.setTestabilityGetter(BrowserGetTestability());
    return Injector.map({
      TestabilityRegistry: registry,
    });
  }

  TransitionalAppHost._();

  /// When creating new root injectors for app, this Injector is the parent.
  final rootInjector = _createRootInjector();
}

/// Top-levels and static state.
final appGlobals = TransitionalAppHost._();
