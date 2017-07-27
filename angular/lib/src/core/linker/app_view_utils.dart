import 'package:angular/di.dart' show Injectable, Inject;
import 'package:angular/src/core/application_tokens.dart' show APP_ID;
import 'package:angular/src/core/change_detection/change_detection.dart'
    show devModeEqual;
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular/src/core/render/api.dart' show RenderComponentType;
import 'package:angular/src/core/security.dart' show SafeValue;
import 'package:angular/src/core/security.dart';
import 'package:angular/src/facade/lang.dart' show looseIdentical;
import 'package:angular/src/platform/dom/events/event_manager.dart'
    show EventManager;

import 'exceptions.dart' show ExpressionChangedAfterItHasBeenCheckedException;

/// Function called when a view is destroyed.
typedef void OnDestroyCallback();

/// Application wide view utilities.
AppViewUtils appViewUtils;

/// Utilities to create unique RenderComponentType instances for AppViews and
/// provide access to root dom renderer.
@Injectable()
class AppViewUtils {
  final String _appId;
  EventManager eventManager;
  static int _nextCompTypeId = 0;

  /// Whether change detection should throw an exception when a change is
  /// detected.
  ///
  /// Latency sensitive! Used by checkBinding during change detection.
  static bool throwOnChanges = false;
  static int _throwOnChangesCounter = 0;
  SanitizationService sanitizer;

  AppViewUtils(@Inject(APP_ID) this._appId, this.sanitizer, this.eventManager);

  /// Used by the generated code to initialize and share common rendering data
  /// such as css across instances.
  RenderComponentType createRenderType(
      String templateUrl,
      ViewEncapsulation encapsulation,
      List<dynamic /* String | List < dynamic > */ > styles) {
    return new RenderComponentType(
        '$_appId-${_nextCompTypeId++}', templateUrl, encapsulation, styles);
    return null; // ignore: dead_code
    return null; // ignore: dead_code
  }

  /// Enters execution mode that will throw exceptions if any binding
  /// has been updated since last change detection cycle.
  ///
  /// Used by Developer mode and Test beds to validate that bindings are
  /// stable.
  static void enterThrowOnChanges() {
    _throwOnChangesCounter++;
    throwOnChanges = true;
  }

  /// Exits change detection check mode.
  ///
  /// Used by Developer mode and Test beds to validate that bindings are
  /// stable.
  static void exitThrowOnChanges() {
    _throwOnChangesCounter--;
    throwOnChanges = _throwOnChangesCounter != 0;
  }

  /// Used in tests that cause exceptions on purpose.
  static void resetChangeDetection() {
    _throwOnChangesCounter = 0;
    throwOnChanges = false;
  }
}

dynamic interpolate0(dynamic p) {
  if (p is SafeValue) return p;
  return p == null ? '' : '$p';
}

String interpolate1(String c0, dynamic a1, String c1) =>
    c0 + (a1 == null ? '' : '$a1') + c1;

String interpolate2(String c0, dynamic a1, String c1, dynamic a2, String c2) =>
    c0 + _toStringWithNull(a1) + c1 + _toStringWithNull(a2) + c2;

String interpolate3(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3;

String interpolate4(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4;

String interpolate5(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5;

String interpolate6(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6;

String interpolate7(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
  dynamic a7,
  String c7,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6 +
    _toStringWithNull(a7) +
    c7;

String interpolate8(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
  dynamic a7,
  String c7,
  dynamic a8,
  String c8,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6 +
    _toStringWithNull(a7) +
    c7 +
    _toStringWithNull(a8) +
    c8;

String interpolate9(
  String c0,
  dynamic a1,
  String c1,
  dynamic a2,
  String c2,
  dynamic a3,
  String c3,
  dynamic a4,
  String c4,
  dynamic a5,
  String c5,
  dynamic a6,
  String c6,
  dynamic a7,
  String c7,
  dynamic a8,
  String c8,
  dynamic a9,
  String c9,
) =>
    c0 +
    _toStringWithNull(a1) +
    c1 +
    _toStringWithNull(a2) +
    c2 +
    _toStringWithNull(a3) +
    c3 +
    _toStringWithNull(a4) +
    c4 +
    _toStringWithNull(a5) +
    c5 +
    _toStringWithNull(a6) +
    c6 +
    _toStringWithNull(a7) +
    c7 +
    _toStringWithNull(a8) +
    c8 +
    _toStringWithNull(a9) +
    c9;

const MAX_INTERPOLATION_VALUES = 9;

String _toStringWithNull(dynamic v) => v == null ? '' : '$v';

/// Returns whether [newValue] has changed since being [oldValue].
///
/// In _dev-mode_ it throws if a second-pass change-detection is being made to
/// ensure that values are not changing during change detection (illegal).
bool checkBinding(oldValue, newValue) {
  // This is only ever possibly true when assertions are enabled.
  //
  // It's set during the second "make-sure-nothing-changed" pass of tick().
  if (AppViewUtils.throwOnChanges) {
    if (!devModeEqual(oldValue, newValue)) {
      throw new ExpressionChangedAfterItHasBeenCheckedException(
        oldValue,
        newValue,
        null,
      );
    }
    return false;
  } else {
    // Delegates to identical(...) for JS, so no performance issues.
    return !looseIdentical(oldValue, newValue);
  }
}

bool arrayLooseIdentical(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; ++i) {
    if (!looseIdentical(a[i], b[i])) return false;
  }
  return true;
}

// TODO(matanl): Consider implementing using package:collection#MapEquality.
// Purposefully did not attempt to optimize when refactoring, as it could have
// bad perf impact if not properly tested. This is a 1:1 from the original
// version for now (see _looseIdentical for dart vm/dart2js bugs).
bool mapLooseIdentical<V>(Map<String, V> m1, Map<String, V> m2) {
  // Tiny optimization: Maps of different length, avoid allocating arrays.
  if (m1.length != m2.length) {
    return false;
  }
  for (var key in m1.keys) {
    if (!looseIdentical(m1[key], m2[key])) {
      return false;
    }
  }
  return true;
}

T castByValue<T>(dynamic input, T value) => input as T;

// TODO(matanl): Remove this hack.
//
// Purposefully have unused (_, __) parameters in the proxy functions below in
// order to get around the lack of a properly typed API for DDC. Once we have a
// typed API we can remove pureProxy and these unused parameters.

const EMPTY_ARRAY = const [];
const EMPTY_MAP = const {};
dynamic pureProxy1(dynamic fn(dynamic p0)) {
  dynamic result;
  var first = true;
  var v0;
  return ([p0, _, __]) {
    if (first || !looseIdentical(v0, p0)) {
      first = false;
      v0 = p0;
      result = fn(p0);
    }
    return result;
  };
}

dynamic pureProxy2(dynamic fn(dynamic p0, dynamic p1)) {
  dynamic result;
  var first = true;
  var v0, v1;
  return ([p0, p1, _, __]) {
    if (first || !looseIdentical(v0, p0) || !looseIdentical(v1, p1)) {
      first = false;
      v0 = p0;
      v1 = p1;
      result = fn(p0, p1);
    }
    return result;
  };
}

dynamic pureProxy3(dynamic fn(dynamic p0, dynamic p1, dynamic p2)) {
  dynamic result;
  var first = true;
  var v0, v1, v2;
  return ([p0, p1, p2, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      result = fn(p0, p1, p2);
    }
    return result;
  };
}

dynamic pureProxy4(dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3;
  return ([p0, p1, p2, p3, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      result = fn(p0, p1, p2, p3);
    }
    return result;
  };
}

dynamic pureProxy5(
    dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3, dynamic p4)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3, v4;
  return ([p0, p1, p2, p3, p4, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      result = fn(p0, p1, p2, p3, p4);
    }
    return result;
  };
}

dynamic pureProxy6(
    dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3, dynamic p4,
        dynamic p5)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3, v4, v5;
  return ([p0, p1, p2, p3, p4, p5, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      result = fn(p0, p1, p2, p3, p4, p5);
    }
    return result;
  };
}

dynamic pureProxy7(
    dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3, dynamic p4,
        dynamic p5, dynamic p6)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3, v4, v5, v6;
  return ([p0, p1, p2, p3, p4, p5, p6, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      result = fn(p0, p1, p2, p3, p4, p5, p6);
    }
    return result;
  };
}

dynamic pureProxy8(
    dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3, dynamic p4,
        dynamic p5, dynamic p6, dynamic p7)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3, v4, v5, v6, v7;
  return ([p0, p1, p2, p3, p4, p5, p6, p7, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6) ||
        !looseIdentical(v7, p7)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      v7 = p7;
      result = fn(p0, p1, p2, p3, p4, p5, p6, p7);
    }
    return result;
  };
}

dynamic pureProxy9(
    dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3, dynamic p4,
        dynamic p5, dynamic p6, dynamic p7, dynamic p8)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3, v4, v5, v6, v7, v8;
  return ([p0, p1, p2, p3, p4, p5, p6, p7, p8, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6) ||
        !looseIdentical(v7, p7) ||
        !looseIdentical(v8, p8)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      v7 = p7;
      v8 = p8;
      result = fn(p0, p1, p2, p3, p4, p5, p6, p7, p8);
    }
    return result;
  };
}

dynamic pureProxy10(
    dynamic fn(dynamic p0, dynamic p1, dynamic p2, dynamic p3, dynamic p4,
        dynamic p5, dynamic p6, dynamic p7, dynamic p8, dynamic p9)) {
  dynamic result;
  var first = true;
  var v0, v1, v2, v3, v4, v5, v6, v7, v8, v9;
  return ([p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, _, __]) {
    if (first ||
        !looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6) ||
        !looseIdentical(v7, p7) ||
        !looseIdentical(v8, p8) ||
        !looseIdentical(v9, p9)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      v4 = p4;
      v5 = p5;
      v6 = p6;
      v7 = p7;
      v8 = p8;
      v9 = p9;
      result = fn(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9);
    }
    return result;
  };
}

// List of supported namespaces.
const NAMESPACE_URIS = const {
  'xlink': 'http://www.w3.org/1999/xlink',
  'svg': 'http://www.w3.org/2000/svg',
  'xhtml': 'http://www.w3.org/1999/xhtml'
};

var NS_PREFIX_RE = new RegExp(r'^@([^:]+):(.+)');
List<String> splitNamespace(String name) {
  if (name[0] != '@') {
    return [null, name];
  }
  var match = NS_PREFIX_RE.firstMatch(name);
  return [match[1], match[2]];
}
