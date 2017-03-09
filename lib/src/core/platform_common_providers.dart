import 'application_ref.dart' show PLATFORM_CORE_PROVIDERS;
import 'di.dart' show Provider;
import 'reflection/reflection.dart' show Reflector, reflector;
import 'testability/testability.dart' show TestabilityRegistry;

Reflector reflectorFactory() {
  return reflector;
}

/// A default set of providers which should be included in any Angular platform.
const List<dynamic /* Type | Provider | List < dynamic > */ >
    PLATFORM_COMMON_PROVIDERS = const [
  PLATFORM_CORE_PROVIDERS,
  const Provider(Reflector, useFactory: reflectorFactory, deps: const []),
  TestabilityRegistry,
];
