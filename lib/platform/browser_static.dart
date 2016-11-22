library angular2.platform.browser_static;

import "dart:async";

import "package:angular2/core.dart"
    show
        ComponentRef,
        coreLoadAndBootstrap,
        ReflectiveInjector,
        PlatformRef,
        getPlatform,
        createPlatform,
        PLATFORM_INITIALIZER,
        MapInjector;
import "package:angular2/src/core/application_ref.dart" show PlatformRefImpl;
import "package:angular2/src/core/reflection/reflection.dart"
    show Reflector, reflector;
import "package:angular2/src/core/testability/testability.dart"
    show TestabilityRegistry;
import "package:angular2/src/platform/browser_common.dart"
    show BROWSER_APP_COMMON_PROVIDERS, createInitDomAdapter;

export "package:angular2/src/core/angular_entrypoint.dart";
export "package:angular2/src/platform/browser_common.dart"
    show
        BROWSER_PROVIDERS,
        BrowserDomAdapter,
        Title,
        enableDebugTools,
        disableDebugTools;

/// An array of providers that should be passed into [application()] when
/// bootstrapping a component when all templates have been precompiled offline.
const List<dynamic> BROWSER_APP_PROVIDERS = const [
  BROWSER_APP_COMMON_PROVIDERS,
];

PlatformRef browserStaticPlatform() {
  var platform = getPlatform();
  if (platform == null) {
    var tokens = new Map();
    platform = new PlatformRefImpl();
    tokens[PlatformRef] = platform;
    tokens[PlatformRefImpl] = platform;
    tokens[Reflector] = reflector;
    var testabilityRegistry = new TestabilityRegistry();
    tokens[TestabilityRegistry] = testabilityRegistry;
    tokens[PLATFORM_INITIALIZER] = [createInitDomAdapter(testabilityRegistry)];
    createPlatform(new MapInjector(null, tokens));
  }
  return platform;
}

/// See [bootstrap] for more information.
Future<ComponentRef> bootstrapStatic(Type appComponentType,
    [List customProviders, Function initReflector]) {
  if (initReflector != null) {
    initReflector();
  }
  var appProviders = customProviders != null
      ? [BROWSER_APP_PROVIDERS, customProviders]
      : BROWSER_APP_PROVIDERS;
  PlatformRef platformRef = browserStaticPlatform();
  var appInjector =
      ReflectiveInjector.resolveAndCreate(appProviders, platformRef.injector);
  return coreLoadAndBootstrap(appInjector, appComponentType);
}
