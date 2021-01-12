import 'dart:developer';
import 'dart:html' as html;

import 'package:angular/src/core/exception_handler.dart';

import '../devtools.dart';
import 'application_ref.dart';
import 'zone/ng_zone.dart';

/// Represents the app running on a page.
///
/// This is a placeholder for a formal app partitioning API (http://b/124374258)
/// which will largely inform how app-wide services are initialized and used.
class App {
  static App? _instance;

  /// The currently running [App].
  static App get instance {
    assert(_instance != null, 'App.ensureInitialized() must be called first');
    return _instance!;
  }

  /// Ensures all singleton and app-wide services are initialized.
  static App ensureInitialized() {
    if (_instance == null) {
      _instance = App._();

      // Register service extensions.
      if (isDevToolsEnabled) {
        ComponentInspector.instance.registerServiceExtensions();

        // Indicates that all service extensions have been registered. Any
        // external tool intending to call service extensions should ensure this
        // event has been posted.
        // TODO(b/158602712): register extension for querying this state.
        postEvent('angular.initialized', {});
      }
    }
    return _instance!;
  }

  /// A transitional API to connect with [ApplicationRef].
  // TODO(b/124374258): replace with formal partitioning API.
  static void setLegacyApp(ApplicationRef appRef) {
    ensureInitialized()._appRef = appRef;
  }

  App._();

  /// A reference to a running app.
  ApplicationRef? _appRef;

  /// Returns the app's [NgZone].
  NgZone get zone {
    _assertDidSetLegacyApp();
    return _appRef!.zone;
  }

  /// Assert that this has been connected to an [ApplicationRef].
  void _assertDidSetLegacyApp() {
    assert(_appRef != null, 'App.setLegacyApp() must be called first');
  }
}

/// An extension for debugging [App] with developer tools.
extension DebugApp on App {
  /// Returns the app's [ExceptionHandler].
  // TODO(b/159650979): determine whether this should be public.
  ExceptionHandler get exceptionHandler {
    _assertDidSetLegacyApp();
    return _appRef!.exceptionHandler;
  }

  /// Returns each root component's root DOM element.
  Iterable<html.Element> get rootElements {
    _assertDidSetLegacyApp();
    return _appRef!.rootComponents.map((component) => component.location);
  }
}
