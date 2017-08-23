import "package:angular/core.dart"
    show ExceptionHandler, APPLICATION_COMMON_PROVIDERS, TestabilityRegistry;
import "package:angular/src/core/di.dart" show Injectable, Provider;
import "package:angular/src/core/testability/testability.dart" show Testability;
import "package:angular/src/platform/browser/exceptions.dart"
    show BrowserExceptionHandler;
import "package:angular/src/security/dom_sanitization_service.dart";
import "package:angular/src/security/dom_sanitization_service_impl.dart";

import "browser/testability.dart" show BrowserGetTestability;
import "dom/events/dom_events.dart" show DomEventsPlugin;
import "dom/events/event_manager.dart"
    show EventManager, EventManagerPlugin, EVENT_MANAGER_PLUGINS;
import "dom/events/hammer_gestures.dart"
    show HAMMER_GESTURE_CONFIG, HammerGestureConfig;
import "dom/events/hammer_gestures.dart" show HammerGesturesPlugin;
import "dom/events/key_events.dart" show KeyEventsPlugin;

export "browser/tools/tools.dart" show enableDebugTools, disableDebugTools;
export "dom/dom_tokens.dart" show DOCUMENT;
export "dom/events/hammer_gestures.dart"
    show HAMMER_GESTURE_CONFIG, HammerGestureConfig;

const List BROWSER_SANITIZATION_PROVIDERS = const [
  const Provider(SanitizationService, useExisting: DomSanitizationService),
  const Provider(DomSanitizationService, useClass: DomSanitizationServiceImpl),
];

/// A set of providers to initialize an Angular application in a web browser.
///
/// Used automatically by `bootstrap`, or can be passed to
/// [PlatformRef.application].
const List<dynamic> BROWSER_APP_COMMON_PROVIDERS = const [
  APPLICATION_COMMON_PROVIDERS,
  BROWSER_SANITIZATION_PROVIDERS,
  const Provider(ExceptionHandler, useClass: BrowserExceptionHandler),
  DomEventsPlugin,
  KeyEventsPlugin,
  HammerGesturesPlugin,
  const Provider(EVENT_MANAGER_PLUGINS, useFactory: createEventPlugins),
  const Provider(HAMMER_GESTURE_CONFIG, useClass: HammerGestureConfig),
  Testability,
  EventManager,
];

@Injectable()
List<EventManagerPlugin> createEventPlugins(DomEventsPlugin dom,
        KeyEventsPlugin keys, HammerGesturesPlugin hammer) =>
    new List<EventManagerPlugin>.unmodifiable([dom, keys, hammer]);

Function createInitDomAdapter(TestabilityRegistry testabilityRegistry) {
  return () {
    testabilityRegistry.setTestabilityGetter(new BrowserGetTestability());
  };
}
