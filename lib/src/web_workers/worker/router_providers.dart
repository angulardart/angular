library angular2.src.web_workers.worker.router_providers;

import "dart:async";

import "package:angular2/core.dart" show Provider, NgZone, APP_INITIALIZER;
import "package:angular2/platform/common.dart" show PlatformLocation;
import "package:angular2/src/router/router_providers_common.dart"
    show ROUTER_PROVIDERS_COMMON;

import "platform_location.dart" show WebWorkerPlatformLocation;

var WORKER_APP_ROUTER = [
  ROUTER_PROVIDERS_COMMON,
  new Provider(PlatformLocation, useClass: WebWorkerPlatformLocation),
  new Provider(APP_INITIALIZER,
      useFactory: (WebWorkerPlatformLocation platformLocation, NgZone zone) =>
          () => initRouter(platformLocation, zone),
      multi: true,
      deps: [PlatformLocation, NgZone])
];
Future<bool> initRouter(
    WebWorkerPlatformLocation platformLocation, NgZone zone) {
  return zone.runGuarded(() {
    return platformLocation.init();
  });
}
