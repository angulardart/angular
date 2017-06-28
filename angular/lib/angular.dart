/// The primary library for Angular Dart.
library angular;

export 'core.dart';
export 'src/common/common_directives.dart';
export 'src/common/directives.dart';
export 'src/common/forms.dart';
export 'src/common/pipes.dart';
export 'src/core/angular_entrypoint.dart' show AngularEntrypoint;
export 'src/core/application_tokens.dart' hide APP_ID_RANDOM_PROVIDER;
export 'src/core/url_resolver.dart';
export 'src/platform/bootstrap.dart';
export 'src/platform/dom/dom_tokens.dart';
export 'src/platform/dom/events/event_manager.dart' show EventManagerPlugin;
