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
        assertPlatform,
        PLATFORM_INITIALIZER,
        MapInjector;
import "package:angular2/src/core/application_ref.dart" show PlatformRef_;
import "package:angular2/src/core/console.dart" show Console;
import "package:angular2/src/core/reflection/reflection.dart"
    show Reflector, reflector;
import "package:angular2/src/core/reflection/reflector_reader.dart"
    show ReflectorReader;
import "package:angular2/src/core/testability/testability.dart"
    show TestabilityRegistry;
import "package:angular2/src/platform/browser_common.dart"
    show
        BROWSER_APP_COMMON_PROVIDERS,
        BROWSER_PLATFORM_MARKER,
        createInitDomAdapter;

export "package:angular2/src/core/angular_entrypoint.dart";
export "package:angular2/src/platform/browser_common.dart"
    show
        BROWSER_PROVIDERS,
        ELEMENT_PROBE_PROVIDERS,
        ELEMENT_PROBE_PROVIDERS_PROD_MODE,
        inspectNativeElement,
        BrowserDomAdapter,
        By,
        Title,
        enableDebugTools,
        disableDebugTools;

/// An array of providers that should be passed into [application()] when
/// bootstrapping a component when all templates have been precompiled offline.
const List<dynamic> BROWSER_APP_PROVIDERS = const [
  BROWSER_APP_COMMON_PROVIDERS,
];

PlatformRef browserStaticPlatform() {
  if (getPlatform() == null) {
    var tokens = new Map<dynamic, dynamic>();
    var platform = new PlatformRef_();
    tokens[PlatformRef] = platform;
    tokens[PlatformRef_] = platform;
    tokens[Reflector] = reflector;
    tokens[ReflectorReader] = reflector;
    var testabilityRegistry = new TestabilityRegistry();
    tokens[TestabilityRegistry] = testabilityRegistry;
    tokens[Console] = new Console();
    tokens[BROWSER_PLATFORM_MARKER] = true;
    tokens[PLATFORM_INITIALIZER] = [createInitDomAdapter(testabilityRegistry)];
    createPlatform(new MapInjector(null, tokens));
  }
  return assertPlatform(BROWSER_PLATFORM_MARKER);
}

/// See [bootstrap] for more information.
Future<ComponentRef> bootstrapStatic(Type appComponentType,
    [List<dynamic> customProviders, Function initReflector]) {
  if (initReflector != null) initReflector();
  var appProviders = customProviders != null
      ? [BROWSER_APP_PROVIDERS, customProviders]
      : BROWSER_APP_PROVIDERS;
  PlatformRef platformRef = browserStaticPlatform();
  var appInjector =
      ReflectiveInjector.resolveAndCreate(appProviders, platformRef.injector);
  return coreLoadAndBootstrap(appInjector, appComponentType);
}
