import "package:angular2/src/core/di.dart" show Provider;

import "application_ref.dart" show APPLICATION_CORE_PROVIDERS;
import "application_tokens.dart" show APP_ID_RANDOM_PROVIDER;
import "change_detection/change_detection.dart"
    show
        IterableDiffers,
        defaultIterableDiffers,
        KeyValueDiffers,
        defaultKeyValueDiffers;
import "linker/app_view_utils.dart" show AppViewUtils;
import "linker/component_resolver.dart" show ComponentResolver;
import "linker/component_resolver.dart" show ReflectorComponentResolver;
import "linker/dynamic_component_loader.dart" show DynamicComponentLoader;
import "linker/dynamic_component_loader.dart" show DynamicComponentLoaderImpl;

Type ___unused;

/// A default set of providers which should be included in any Angular
/// application, regardless of the platform it runs onto.
const List<dynamic /* Type | Provider | List < dynamic > */ >
    APPLICATION_COMMON_PROVIDERS = const [
  APPLICATION_CORE_PROVIDERS,
  const Provider(ComponentResolver, useClass: ReflectorComponentResolver),
  APP_ID_RANDOM_PROVIDER,
  AppViewUtils,
  const Provider(IterableDiffers, useValue: defaultIterableDiffers),
  const Provider(KeyValueDiffers, useValue: defaultKeyValueDiffers),
  const Provider(DynamicComponentLoader, useClass: DynamicComponentLoaderImpl)
];
