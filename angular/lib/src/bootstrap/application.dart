import 'package:meta/meta.dart';

import '../core/application_ref.dart';

/// **INTERNAL ONLY.**
///
/// Set to the context of the current [ApplicationRef] while executing.
ChangeDetectionHost currentApplication;

/// A host for tracking the current application and stateful components.
///
/// This is a work-in-progress as a refactor in [#1071]
/// (https://github.com/dart-lang/angular/issues/1071).
abstract class ChangeDetectionHost {
  @protected
  @visibleForOverriding
  void reportNoContextException(Object error, [StackTrace trace]);

  void reportComponentException(AppView<void> view, Object error, [StackTrace trace,]);
}
