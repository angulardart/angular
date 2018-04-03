import 'package:angular/di.dart' show Injectable, Inject;
import 'package:angular/src/core/application_tokens.dart' show APP_ID;
import 'package:angular/src/core/change_detection/change_detection.dart'
    show devModeEqual;
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular/src/core/render/api.dart' show RenderComponentType;
import 'package:angular/src/core/security.dart' show SafeValue;
import 'package:angular/src/core/security.dart';
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

/// Flattens a `List<List<?>>` into a `List<?>`.
List<T> flattenNodes<T>(List<List<T>> nodes) {
  final result = <T>[];
  for (var i = 0, l = nodes.length; i < l; i++) {
    result.addAll(nodes[i]);
  }
  return result;
}

dynamic interpolate0(dynamic p) {
  if (p is String) return p;
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
  }
  return !identical(oldValue, newValue);
}

const EMPTY_ARRAY = const <Null>[];
const EMPTY_MAP = const <Null, Null>{};

T Function(S0) pureProxy1<T, S0>(T Function(S0) fn) {
  T result;
  var first = true;
  S0 v0;
  return (S0 p0) {
    if (first || !identical(v0, p0)) {
      first = false;
      v0 = p0;
      result = fn(p0);
    }
    return result;
  };
}

T Function(S0, S1) pureProxy2<T, S0, S1>(T Function(S0, S1) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  return (S0 p0, S1 p1) {
    if (first || !identical(v0, p0) || !identical(v1, p1)) {
      first = false;
      v0 = p0;
      v1 = p1;
      result = fn(p0, p1);
    }
    return result;
  };
}

T Function(S0, S1, S2) pureProxy3<T, S0, S1, S2>(T Function(S0, S1, S2) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  return (S0 p0, S1 p1, S2 p2) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2)) {
      first = false;
      v0 = p0;
      v1 = p1;
      v2 = p2;
      result = fn(p0, p1, p2);
    }
    return result;
  };
}

T Function(S0, S1, S2, S3) pureProxy4<T, S0, S1, S2, S3>(
    T Function(S0, S1, S2, S3) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  return (S0 p0, S1 p1, S2 p2, S3 p3) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3)) {
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

T Function(S0, S1, S2, S3, S4) pureProxy5<T, S0, S1, S2, S3, S4>(
    T Function(S0, S1, S2, S3, S4) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4)) {
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

T Function(S0, S1, S2, S3, S4, S5) pureProxy6<T, S0, S1, S2, S3, S4, S5>(
    T Function(S0, S1, S2, S3, S4, S5) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5)) {
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

T Function(S0, S1, S2, S3, S4, S5, S6)
    pureProxy7<T, S0, S1, S2, S3, S4, S5, S6>(
        T Function(S0, S1, S2, S3, S4, S5, S6) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5, S6 p6) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6)) {
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

T Function(S0, S1, S2, S3, S4, S5, S6, S7)
    pureProxy8<T, S0, S1, S2, S3, S4, S5, S6, S7>(
        T Function(S0, S1, S2, S3, S4, S5, S6, S7) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  S7 v7;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5, S6 p6, S7 p7) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6) ||
        !identical(v7, p7)) {
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

T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8)
    pureProxy9<T, S0, S1, S2, S3, S4, S5, S6, S7, S8>(
        T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  S7 v7;
  S8 v8;
  return (S0 p0, S1 p1, S2 p2, S3 p3, S4 p4, S5 p5, S6 p6, S7 p7, S8 p8) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6) ||
        !identical(v7, p7) ||
        !identical(v8, p8)) {
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

T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8, S9)
    pureProxy10<T, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9>(
        T Function(S0, S1, S2, S3, S4, S5, S6, S7, S8, S9) fn) {
  T result;
  var first = true;
  S0 v0;
  S1 v1;
  S2 v2;
  S3 v3;
  S4 v4;
  S5 v5;
  S6 v6;
  S7 v7;
  S8 v8;
  S9 v9;
  return (
    S0 p0,
    S1 p1,
    S2 p2,
    S3 p3,
    S4 p4,
    S5 p5,
    S6 p6,
    S7 p7,
    S8 p8,
    S9 p9,
  ) {
    if (first ||
        !identical(v0, p0) ||
        !identical(v1, p1) ||
        !identical(v2, p2) ||
        !identical(v3, p3) ||
        !identical(v4, p4) ||
        !identical(v5, p5) ||
        !identical(v6, p6) ||
        !identical(v7, p7) ||
        !identical(v8, p8) ||
        !identical(v9, p9)) {
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

var NS_PREFIX_RE = new RegExp(r'^@([^:]+):(.+)');
List<String> splitNamespace(String name) {
  if (name[0] != '@') {
    return [null, name];
  }
  var match = NS_PREFIX_RE.firstMatch(name);
  return [match[1], match[2]];
}
