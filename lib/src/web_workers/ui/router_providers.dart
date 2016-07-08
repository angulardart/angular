library angular2.src.web_workers.ui.router_providers;

import "package:angular2/core.dart"
    show APP_INITIALIZER, Provider, Injector, NgZone;
import "package:angular2/src/platform/browser/location/browser_platform_location.dart"
    show BrowserPlatformLocation;

import "platform_location.dart" show MessageBasedPlatformLocation;

const WORKER_RENDER_ROUTER = const [
  MessageBasedPlatformLocation,
  BrowserPlatformLocation,
  const Provider(APP_INITIALIZER,
      useFactory: initRouterListeners, multi: true, deps: const [Injector])
];
dynamic /* () => void */ initRouterListeners(Injector injector) {
  return () {
    var zone = injector.get(NgZone);
    zone.runGuarded(() => injector.get(MessageBasedPlatformLocation).start());
  };
}
