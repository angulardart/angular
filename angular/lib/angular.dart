/// The primary library for the [AngularDart web framework][AngularDart].
///
/// Import this library as follows:
///
/// ```
/// import 'package:angular/angular.dart';
/// ```
///
/// For help using this library, see the AngularDart documentation:
///
/// * [AngularDart guide][]
/// * [AngularDart cheat sheet][cheatsheet]
///
/// [AngularDart]: https://webdev.dartlang.org/angular
/// [AngularDart guide]: https://webdev.dartlang.org/angular/guide
/// [cheatsheet]: https://webdev.dartlang.org/angular/cheatsheet

library angular;

export 'core.dart';
export 'src/common/common_directives.dart';
export 'src/common/directives.dart';
export 'src/common/pipes.dart';
export 'src/core/angular_entrypoint.dart' show AngularEntrypoint;
export 'src/core/application_tokens.dart' hide APP_ID_RANDOM_PROVIDER;
export 'src/platform/bootstrap.dart';
export 'src/platform/dom/dom_tokens.dart';
export 'src/platform/dom/events/event_manager.dart' show EventManagerPlugin;
