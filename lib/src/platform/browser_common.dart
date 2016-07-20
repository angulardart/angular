library angular2.src.platform.browser_common;

import "package:angular2/common.dart"
    show COMMON_DIRECTIVES, COMMON_PIPES, FORM_PROVIDERS;
import "package:angular2/core.dart"
    show
        PLATFORM_INITIALIZER,
        PLATFORM_DIRECTIVES,
        PLATFORM_PIPES,
        ExceptionHandler,
        RootRenderer,
        APPLICATION_COMMON_PROVIDERS,
        PLATFORM_COMMON_PROVIDERS,
        TestabilityRegistry;
import "package:angular2/platform/common_dom.dart" show ELEMENT_PROBE_PROVIDERS;
import "package:angular2/src/animate/animation_builder.dart"
    show AnimationBuilder;
import "package:angular2/src/animate/browser_details.dart" show BrowserDetails;
import "package:angular2/src/compiler/xhr.dart" show XHR;
import "package:angular2/src/core/di.dart" show Provider, OpaqueToken;
import "package:angular2/src/core/profile/wtf_init.dart" show wtfInit;
import "package:angular2/src/core/testability/testability.dart"
    show Testability;
import "package:angular2/src/platform/browser/testability.dart"
    show BrowserGetTestability;
import "package:angular2/src/platform/browser/xhr_cache.dart" show CachedXHR;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/platform/dom/dom_renderer.dart"
    show DomRootRenderer, DomRootRenderer_;
import "package:angular2/src/platform/dom/dom_tokens.dart" show DOCUMENT;
import "package:angular2/src/platform/dom/events/dom_events.dart"
    show DomEventsPlugin;
import "package:angular2/src/platform/dom/events/event_manager.dart"
    show EventManager, EVENT_MANAGER_PLUGINS;
import "package:angular2/src/platform/dom/events/hammer_gestures.dart"
    show HammerGesturesPlugin;
import "package:angular2/src/platform/dom/events/hammer_gestures.dart"
    show HAMMER_GESTURE_CONFIG, HammerGestureConfig;
import "package:angular2/src/platform/dom/events/key_events.dart"
    show KeyEventsPlugin;
import "package:angular2/src/platform/dom/shared_styles_host.dart"
    show DomSharedStylesHost;
import "package:angular2/src/platform/dom/shared_styles_host.dart"
    show SharedStylesHost;
import "package:angular2/src/security/dom_sanitization_service.dart";

import "browser/browser_adapter.dart" show BrowserDomAdapter;

export "package:angular2/platform/common_dom.dart"
    show
        ELEMENT_PROBE_PROVIDERS,
        ELEMENT_PROBE_PROVIDERS_PROD_MODE,
        inspectNativeElement,
        By;
export "package:angular2/src/platform/browser/title.dart" show Title;
export "package:angular2/src/platform/browser/tools/tools.dart"
    show enableDebugTools, disableDebugTools;
export "package:angular2/src/platform/dom/dom_tokens.dart" show DOCUMENT;

export "browser/browser_adapter.dart" show BrowserDomAdapter;
export "dom/events/hammer_gestures.dart"
    show HAMMER_GESTURE_CONFIG, HammerGestureConfig;

const BROWSER_PLATFORM_MARKER = const OpaqueToken("BrowserPlatformMarker");
/**
 * A set of providers to initialize the Angular platform in a web browser.
 *
 * Used automatically by `bootstrap`, or can be passed to [platform].
 */
const List<dynamic> BROWSER_PROVIDERS = const [
  const Provider(BROWSER_PLATFORM_MARKER, useValue: true),
  PLATFORM_COMMON_PROVIDERS,
  const Provider(PLATFORM_INITIALIZER,
      useFactory: createInitDomAdapter,
      multi: true,
      deps: const [TestabilityRegistry])
];
ExceptionHandler exceptionHandler() {
  // But must not rethrow exceptions in Dart.
  return new ExceptionHandler(DOM, false);
}

dynamic document() {
  return DOM.defaultDoc();
}

const List BROWSER_SANITIZATION_PROVIDERS = const [
  const Provider(SanitizationService, useExisting: DomSanitizationService),
  const Provider(DomSanitizationService, useClass: DomSanitizationServiceImpl),
];

/**
 * A set of providers to initialize an Angular application in a web browser.
 *
 * Used automatically by `bootstrap`, or can be passed to [PlatformRef.application].
 */
const List<dynamic> BROWSER_APP_COMMON_PROVIDERS = const [
  APPLICATION_COMMON_PROVIDERS,
  BROWSER_SANITIZATION_PROVIDERS,
  FORM_PROVIDERS,
  const Provider(PLATFORM_PIPES, useValue: COMMON_PIPES, multi: true),
  const Provider(PLATFORM_DIRECTIVES, useValue: COMMON_DIRECTIVES, multi: true),
  const Provider(ExceptionHandler,
      useFactory: exceptionHandler, deps: const []),
  const Provider(DOCUMENT, useFactory: document, deps: const []),
  const Provider(EVENT_MANAGER_PLUGINS, useClass: DomEventsPlugin, multi: true),
  const Provider(EVENT_MANAGER_PLUGINS, useClass: KeyEventsPlugin, multi: true),
  const Provider(EVENT_MANAGER_PLUGINS,
      useClass: HammerGesturesPlugin, multi: true),
  const Provider(HAMMER_GESTURE_CONFIG, useClass: HammerGestureConfig),
  const Provider(DomRootRenderer, useClass: DomRootRenderer_),
  const Provider(RootRenderer, useExisting: DomRootRenderer),
  const Provider(SharedStylesHost, useExisting: DomSharedStylesHost),
  DomSharedStylesHost,
  Testability,
  BrowserDetails,
  AnimationBuilder,
  EventManager,
  ELEMENT_PROBE_PROVIDERS
];
const List<dynamic> CACHED_TEMPLATE_PROVIDER = const [
  const Provider(XHR, useClass: CachedXHR)
];
Function createInitDomAdapter(TestabilityRegistry testabilityRegistry) {
  return () {
    BrowserDomAdapter.makeCurrent();
    wtfInit();
    testabilityRegistry.setTestabilityGetter(new BrowserGetTestability());
  };
}
