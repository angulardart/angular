import "application_ref.dart" show APPLICATION_CORE_PROVIDERS;
import "application_tokens.dart" show APP_ID_RANDOM_PROVIDER;
import 'di.dart' show Provider;
import "linker/app_view_utils.dart" show AppViewUtils;
import "linker/component_loader.dart";
import "linker/component_resolver.dart" show ComponentResolver;
import "linker/component_resolver.dart" show ReflectorComponentResolver;
import "linker/dynamic_component_loader.dart" show SlowComponentLoader;

/// A default set of providers which should be included in any Angular
/// application, regardless of the platform it runs onto.
const List APPLICATION_COMMON_PROVIDERS = const [
  APPLICATION_CORE_PROVIDERS,
  const Provider(ComponentResolver, useClass: ReflectorComponentResolver),
  APP_ID_RANDOM_PROVIDER,
  AppViewUtils,
  // ignore: deprecated_member_use
  const Provider(SlowComponentLoader),
  const Provider(ComponentLoader),
];
