import 'dart:html';

import '../core/application_tokens.dart';
import '../core/render/api.dart';
import '../core/testability/testability.dart';
import '../di/injector/injector.dart';
import '../platform/browser/testability.dart';
import '../platform/dom/shared_styles_host.dart';
import '../runtime.dart';

/// A singleton class (per instance of the Dart runtime) for AngularDart.
///
/// Common (platform-level) services are shared across applications from here.
class PlatformRef {
  final List<void Function()> _disposers = [];

  bool _disposed = false;
  bool _initialized = false;
  Injector _injector;

  PlatformRef._();

  /// Shared global injector for services such as the style host.
  Injector get injector => _injector;

  /// An internal method to initialize global variables for the platform.
  void _initialize(Injector injector) {
    if (isDevMode && _initialized) {
      throw new StateError('Already initialized');
    }
    final List<void Function()> functions = injector.get(PLATFORM_INITIALIZER);
    if (functions != null) {
      for (var l = functions.length, i = 0; i < l; i++) {
        functions[i]();
      }
    }
    _injector = injector;
    _initialized = true;
  }

  /// Destroy the AngularDart platform.
  void dispose() {
    if (isDevMode && _disposed) {
      throw new StateError('Already disposed');
    }
    _disposed = true;
  }

  /// Registers a [callback] function to be executed on [dispose].
  void registerDisposeListener(void Function() callback) {
    if (isDevMode && _disposed) {
      throw new StateError('Already disposed');
    }
    _disposers.add(callback);
  }
}

/// Global platform shared across every application.
final PlatformRef internalPlatform = _createPlatformSingleton();

/// Creates the global platform.
PlatformRef _createPlatformSingleton() {
  final registry = new TestabilityRegistry();
  final platform = new PlatformRef._();
  final injector = new Injector.map({
    // This is used almost exclusively to just wire up testability. Consider
    // making another (more tree-shakeable) mechanism for this instead of
    // wiring up an injector.
    PLATFORM_INITIALIZER: [
      () {
        registry.setTestabilityGetter(new BrowserGetTestability());
      },
    ],
    PlatformRef: platform,
    TestabilityRegistry: registry,
  });
  sharedStylesHost ??= new DomSharedStylesHost(document);
  platform._initialize(injector);
  return platform;
}
