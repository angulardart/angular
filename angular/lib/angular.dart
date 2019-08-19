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
export 'src/bootstrap/run.dart'
    show runApp, runAppAsync, runAppLegacy, runAppLegacyAsync, bootstrapStatic;
export 'src/common/common_directives.dart';
export 'src/common/directives.dart';
export 'src/common/pipes.dart';
export 'src/core/application_ref.dart' show ApplicationRef;
export 'src/core/linker.dart';
export 'src/core/testability/testability.dart';
export 'src/platform/browser/tools/tools.dart'
    show enableDebugTools, disableDebugTools;
export 'src/runtime/check_binding.dart' show debugCheckBindings;
