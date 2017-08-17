import 'application_ref.dart' show PLATFORM_CORE_PROVIDERS;
import 'testability/testability.dart' show TestabilityRegistry;

/// A default set of providers which should be included in any Angular platform.
const PLATFORM_COMMON_PROVIDERS = const [
  PLATFORM_CORE_PROVIDERS,
  TestabilityRegistry,
];
