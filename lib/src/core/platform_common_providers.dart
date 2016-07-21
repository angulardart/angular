import "package:angular2/src/core/console.dart" show Console;
import "package:angular2/src/core/di.dart" show Provider;
import "package:angular2/src/core/testability/testability.dart"
    show TestabilityRegistry;

import "application_ref.dart" show PLATFORM_CORE_PROVIDERS;
import "reflection/reflection.dart" show Reflector, reflector;
import "reflection/reflector_reader.dart" show ReflectorReader;

Reflector reflectorFactory() {
  return reflector;
}

/**
 * A default set of providers which should be included in any Angular platform.
 */
const List<dynamic /* Type | Provider | List < dynamic > */ >
    PLATFORM_COMMON_PROVIDERS = const [
  PLATFORM_CORE_PROVIDERS,
  const Provider(Reflector, useFactory: reflectorFactory, deps: const []),
  const Provider(ReflectorReader, useExisting: Reflector),
  TestabilityRegistry,
  Console
];
