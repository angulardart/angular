import 'package:angular/angular.dart';
import 'package:angular/src/core/change_detection/change_detection.dart';
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/core/linker/view_ref.dart';
import 'package:angular/src/runtime.dart';

/// Runs [component.changeDetectorRef.detectChanges].
///
/// If an error occurs during change detection the component is disabled.
void safeDetectChanges(ComponentRef<void> component) {
  // See https://github.com/dart-lang/angular/issues/1354 for details.
  final viewRef = unsafeCast<ViewRefImpl>(component.hostView);
  if (viewRef.appView.cdState == ChangeDetectorState.Errored) {
    return;
  }
  try {
    // Ideally the router would not rely on calling 'detectChanges'.
    // https://github.com/dart-lang/angular/issues/1356
    component.changeDetectorRef.detectChanges();
  } catch (e, s) {
    final ChangeDetectionHost host = component.injector.get(ApplicationRef);
    host.reportViewException(viewRef.appView, e, s);
  }
}
