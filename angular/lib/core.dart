/// @nodoc
library angular.core;

export 'src/core/angular_entrypoint.dart' show AngularEntrypoint;
export 'src/core/application_common_providers.dart';
export 'src/core/application_ref.dart'
    show
        createPlatform,
        disposePlatform,
        getPlatform,
        coreLoadAndBootstrap,
        coreBootstrap,
        createNgZone,
        PlatformRef,
        ApplicationRef;
export 'src/core/application_tokens.dart'
    show APP_ID, APP_INITIALIZER, PACKAGE_ROOT_URL, PLATFORM_INITIALIZER;
export 'src/core/change_detection.dart';
export 'src/core/di.dart';
export 'src/core/linker.dart';
export 'src/core/metadata.dart';
export 'src/core/render.dart';
export 'src/core/testability/testability.dart';
export 'src/core/url_resolver.dart' show UrlResolver;
export 'src/core/zone.dart';
export 'src/facade/facade.dart';
