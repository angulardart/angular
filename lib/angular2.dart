/// The primary library for Angular Dart.
library angular2;

export 'package:angular2/core.dart';
export 'package:angular2/src/core/angular_entrypoint.dart'
    show AngularEntrypoint;
export 'package:angular2/src/core/application_tokens.dart'
    hide APP_ID_RANDOM_PROVIDER;
export 'package:angular2/src/platform/dom/dom_tokens.dart';
export 'package:angular2/src/platform/dom/events/event_manager.dart'
    show EventManagerPlugin;

// Attention: Don't use angular2/src/compiler/compiler.dart
// for re exports as this will pull in the whole compiler,
// even if only some parts are shown.
// Background: Our transformer generates `initReflector` calls
// for all referenced modules, which will keep all
// types reachable from that module!
export 'package:angular2/src/compiler/url_resolver.dart';
export 'package:angular2/src/compiler/directive_resolver.dart';
export 'package:angular2/src/compiler/view_resolver.dart';

// Used to be package:angular2/common.dart.
export 'src/common/common_directives.dart';
export 'src/common/directives.dart';
export 'src/common/forms.dart';
export 'src/common/pipes.dart';
