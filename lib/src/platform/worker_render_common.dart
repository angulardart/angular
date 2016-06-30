library angular2.src.platform.worker_render_common;

import "package:angular2/src/facade/lang.dart" show IS_DART;
import "package:angular2/src/web_workers/shared/message_bus.dart"
    show MessageBus;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/core.dart"
    show
        PLATFORM_DIRECTIVES,
        PLATFORM_PIPES,
        ComponentRef,
        ExceptionHandler,
        Reflector,
        reflector,
        APPLICATION_COMMON_PROVIDERS,
        PLATFORM_COMMON_PROVIDERS,
        RootRenderer,
        PLATFORM_INITIALIZER,
        APP_INITIALIZER,
        TestabilityRegistry;
import "package:angular2/platform/common_dom.dart"
    show EVENT_MANAGER_PLUGINS, EventManager;
import "package:angular2/src/core/di.dart"
    show provide, Provider, Injector, OpaqueToken;
// TODO change these imports once dom_adapter is moved out of core
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/platform/dom/events/dom_events.dart"
    show DomEventsPlugin;
import "package:angular2/src/platform/dom/events/key_events.dart"
    show KeyEventsPlugin;
import "package:angular2/src/platform/dom/events/hammer_gestures.dart"
    show HammerGesturesPlugin;
import "package:angular2/src/platform/dom/dom_tokens.dart" show DOCUMENT;
import "package:angular2/src/platform/dom/dom_renderer.dart"
    show DomRootRenderer, DomRootRenderer_;
import "package:angular2/src/platform/dom/shared_styles_host.dart"
    show DomSharedStylesHost;
import "package:angular2/src/platform/dom/shared_styles_host.dart"
    show SharedStylesHost;
import "package:angular2/src/animate/browser_details.dart" show BrowserDetails;
import "package:angular2/src/animate/animation_builder.dart"
    show AnimationBuilder;
import "package:angular2/compiler.dart" show XHR;
import "package:angular2/src/platform/browser/xhr_impl.dart" show XHRImpl;
import "package:angular2/src/core/testability/testability.dart"
    show Testability;
import "package:angular2/src/platform/browser/testability.dart"
    show BrowserGetTestability;
import "browser/browser_adapter.dart" show BrowserDomAdapter;
import "package:angular2/src/core/profile/wtf_init.dart" show wtfInit;
import "package:angular2/src/web_workers/ui/renderer.dart"
    show MessageBasedRenderer;
import "package:angular2/src/web_workers/ui/xhr_impl.dart"
    show MessageBasedXHRImpl;
import "package:angular2/src/web_workers/shared/service_message_broker.dart"
    show ServiceMessageBrokerFactory, ServiceMessageBrokerFactory_;
import "package:angular2/src/web_workers/shared/client_message_broker.dart"
    show ClientMessageBrokerFactory, ClientMessageBrokerFactory_;
import "package:angular2/src/platform/browser/location/browser_platform_location.dart"
    show BrowserPlatformLocation;
import "package:angular2/src/web_workers/shared/serializer.dart"
    show Serializer;
import "package:angular2/src/web_workers/shared/api.dart" show ON_WEB_WORKER;
import "package:angular2/src/web_workers/shared/render_store.dart"
    show RenderStore;
import "dom/events/hammer_gestures.dart"
    show HAMMER_GESTURE_CONFIG, HammerGestureConfig;

const OpaqueToken WORKER_SCRIPT = const OpaqueToken("WebWorkerScript");
// Message based Worker classes that listen on the MessageBus
const List<dynamic> WORKER_RENDER_MESSAGING_PROVIDERS = const [
  MessageBasedRenderer,
  MessageBasedXHRImpl
];
const WORKER_RENDER_PLATFORM_MARKER =
    const OpaqueToken("WorkerRenderPlatformMarker");
const List<dynamic> WORKER_RENDER_PLATFORM = const [
  PLATFORM_COMMON_PROVIDERS,
  const Provider(WORKER_RENDER_PLATFORM_MARKER, useValue: true),
  const Provider(PLATFORM_INITIALIZER,
      useFactory: initWebWorkerRenderPlatform,
      multi: true,
      deps: const [TestabilityRegistry])
];
/**
 * A list of [Provider]s. To use the router in a Worker enabled application you must
 * include these providers when setting up the render thread.
 */
const List<dynamic> WORKER_RENDER_ROUTER = const [BrowserPlatformLocation];
const List<dynamic> WORKER_RENDER_APPLICATION_COMMON = const [
  APPLICATION_COMMON_PROVIDERS,
  WORKER_RENDER_MESSAGING_PROVIDERS,
  const Provider(ExceptionHandler,
      useFactory: exceptionHandler, deps: const []),
  const Provider(DOCUMENT, useFactory: document, deps: const []),
  // TODO(jteplitz602): Investigate if we definitely need EVENT_MANAGER on the render thread

  // #5298
  const Provider(EVENT_MANAGER_PLUGINS, useClass: DomEventsPlugin, multi: true),
  const Provider(EVENT_MANAGER_PLUGINS, useClass: KeyEventsPlugin, multi: true),
  const Provider(EVENT_MANAGER_PLUGINS,
      useClass: HammerGesturesPlugin, multi: true),
  const Provider(HAMMER_GESTURE_CONFIG, useClass: HammerGestureConfig),
  const Provider(DomRootRenderer, useClass: DomRootRenderer_),
  const Provider(RootRenderer, useExisting: DomRootRenderer),
  const Provider(SharedStylesHost, useExisting: DomSharedStylesHost),
  const Provider(XHR, useClass: XHRImpl),
  MessageBasedXHRImpl,
  const Provider(ServiceMessageBrokerFactory,
      useClass: ServiceMessageBrokerFactory_),
  const Provider(ClientMessageBrokerFactory,
      useClass: ClientMessageBrokerFactory_),
  Serializer,
  const Provider(ON_WEB_WORKER, useValue: false),
  RenderStore,
  DomSharedStylesHost,
  Testability,
  BrowserDetails,
  AnimationBuilder,
  EventManager
];
initializeGenericWorkerRenderer(Injector injector) {
  var bus = injector.get(MessageBus);
  var zone = injector.get(NgZone);
  bus.attachToZone(zone);
  zone.runGuarded(() {
    WORKER_RENDER_MESSAGING_PROVIDERS.forEach((token) {
      injector.get(token).start();
    });
  });
}

Function initWebWorkerRenderPlatform(TestabilityRegistry registry) {
  return () {
    BrowserDomAdapter.makeCurrent();
    wtfInit();
    registry.setTestabilityGetter(new BrowserGetTestability());
  };
}

ExceptionHandler exceptionHandler() {
  return new ExceptionHandler(DOM, !IS_DART);
}

dynamic document() {
  return DOM.defaultDoc();
}
