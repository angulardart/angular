import 'dart:html' show DocumentFragment, NodeTreeSanitizer;

import 'package:angular/di.dart' show Injectable;
import 'package:angular/src/core/application_tokens.dart' show APP_ID;
import 'package:angular/src/core/change_detection/change_detection.dart'
    show devModeEqual;
import 'package:angular/src/core/security.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_events.dart' show EventManager;
import 'package:meta/dart2js.dart' as dart2js;

import 'exceptions.dart' show ExpressionChangedAfterItHasBeenCheckedException;

/// Application wide view utilities.
AppViewUtils appViewUtils;

/// Utilities to create unique RenderComponentType instances for AppViews and
/// provide access to root dom renderer.
@Injectable()
class AppViewUtils {
  final String appId;
  final EventManager eventManager;
  final SanitizationService sanitizer;

  /// Whether change detection should throw an exception when a change is
  /// detected.
  ///
  /// Latency sensitive! Used by checkBinding during change detection.
  static bool get throwOnChanges => isDevMode && _throwOnChanges;
  static bool _throwOnChanges = false;
  static int _throwOnChangesCounter = 0;

  AppViewUtils(@APP_ID this.appId, this.sanitizer, this.eventManager);

  /// Enters execution mode that will throw exceptions if any binding
  /// has been updated since last change detection cycle.
  ///
  /// Used by Developer mode and Test beds to validate that bindings are
  /// stable.
  static void enterThrowOnChanges() {
    _throwOnChangesCounter++;
    _throwOnChanges = true;
  }

  /// Exits change detection check mode.
  ///
  /// Used by Developer mode and Test beds to validate that bindings are
  /// stable.
  static void exitThrowOnChanges() {
    _throwOnChangesCounter--;
    _throwOnChanges = _throwOnChangesCounter != 0;
  }
}

/// Creates a document fragment from [trustedHtml].
DocumentFragment createTrustedHtml(String trustedHtml) {
  return DocumentFragment.html(
    trustedHtml,
    treeSanitizer: NodeTreeSanitizer.trusted,
  );
}

/// Returns whether [newValue] has changed since being [oldValue].
///
/// In _dev-mode_ it throws if a second-pass change-detection is being made to
/// ensure that values are not changing during change detection (illegal).
@dart2js.tryInline
bool checkBinding(oldValue, newValue) =>
    // This is only ever possibly true when assertions are enabled.
    //
    // It's set during the second "make-sure-nothing-changed" pass of tick().
    AppViewUtils.throwOnChanges
        ? _checkBindingDebug(oldValue, newValue)
        : _checkBindingRelease(oldValue, newValue);

@dart2js.noInline
bool _checkBindingDebug(oldValue, newValue) {
  if (!devModeEqual(oldValue, newValue)) {
    throw ExpressionChangedAfterItHasBeenCheckedException(
      oldValue,
      newValue,
      null,
    );
  }
  return false;
}

@dart2js.tryInline
bool _checkBindingRelease(oldValue, newValue) {
  return !identical(oldValue, newValue);
}
