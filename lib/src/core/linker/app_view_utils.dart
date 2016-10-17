import 'package:angular2/di.dart' show Injectable, Inject;
import 'package:angular2/src/core/application_tokens.dart' show APP_ID;
import 'package:angular2/src/core/change_detection/change_detection.dart'
    show devModeEqual, uninitialized;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/src/core/render/api.dart'
    show RootRenderer, RenderComponentType, Renderer;
import 'package:angular2/src/core/security.dart' show SafeValue;
import 'package:angular2/src/core/security.dart';
import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import 'package:angular2/src/facade/lang.dart' show looseIdentical;

import 'exceptions.dart' show ExpressionChangedAfterItHasBeenCheckedException;

/// Function called when a view is destroyed.
typedef void OnDestroyCallback();

/// Application wide view utilitizes.
AppViewUtils appViewUtils;

/// Utilities to create unique RenderComponentType instances for AppViews and
/// provide access to root dom renderer.
@Injectable()
class AppViewUtils {
  RootRenderer _renderer;
  String _appId;
  static int _nextCompTypeId = 0;

  /// Whether change detection should throw an exception when a change is
  /// detected.
  ///
  /// Latency sensitive! Used by checkBinding during change detection.
  static bool throwOnChanges = false;
  static int _throwOnChangesCounter = 0;
  SanitizationService sanitizer;

  AppViewUtils(this._renderer, @Inject(APP_ID) this._appId, this.sanitizer);

  /// Used by the generated code.
  RenderComponentType createRenderComponentType(
      String templateUrl,
      num slotCount,
      ViewEncapsulation encapsulation,
      List<dynamic /* String | List < dynamic > */ > styles) {
    return new RenderComponentType('${_appId}-${_nextCompTypeId++}',
        templateUrl, slotCount, encapsulation, styles);
  }

  Renderer renderComponent(RenderComponentType renderComponentType) {
    return this._renderer.renderComponent(renderComponentType);
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

List ensureSlotCount(List projectableNodes, int expectedSlotCount) {
  var res;
  if (projectableNodes == null) {
    return const [];
  }
  if (projectableNodes.length < expectedSlotCount) {
    var givenSlotCount = projectableNodes.length;
    res = new List(expectedSlotCount);
    for (var i = 0; i < expectedSlotCount; i++) {
      res[i] = (i < givenSlotCount) ? projectableNodes[i] : const [];
    }
  } else {
    res = projectableNodes;
  }
  return res;
}

dynamic interpolate0(dynamic p) {
  if (p is SafeValue) return p;
  return p == null ? '' : (p is String ? p : p.toString());
}

dynamic interpolate1(String c0, dynamic a1, String c1) =>
    c0 + (a1 == null ? '' : (a1 is String ? a1 : a1.toString())) + c1;

dynamic interpolate2(String c0, dynamic a1, String c1, dynamic a2, String c2) =>
    c0 + _toStringWithNull(a1) + c1 + _toStringWithNull(a2) + c2;

const MAX_INTERPOLATION_VALUES = 9;
String interpolate(num valueCount, String c0, dynamic a1, String c1,
    [dynamic a2,
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
    String c9]) {
  switch (valueCount) {
    case 1:
      return c0 + _toStringWithNull(a1) + c1;
    case 2:
      return c0 + _toStringWithNull(a1) + c1 + _toStringWithNull(a2) + c2;
    case 3:
      return c0 +
          _toStringWithNull(a1) +
          c1 +
          _toStringWithNull(a2) +
          c2 +
          _toStringWithNull(a3) +
          c3;
    case 4:
      return c0 +
          _toStringWithNull(a1) +
          c1 +
          _toStringWithNull(a2) +
          c2 +
          _toStringWithNull(a3) +
          c3 +
          _toStringWithNull(a4) +
          c4;
    case 5:
      return c0 +
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
    case 6:
      return c0 +
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
    case 7:
      return c0 +
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
    case 8:
      return c0 +
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
    case 9:
      return c0 +
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
    default:
      throw new BaseException('''Does not support more than 9 expressions''');
  }
}

String _toStringWithNull(dynamic v) => v?.toString() ?? '';

bool checkBinding(dynamic oldValue, dynamic newValue) {
  if (AppViewUtils.throwOnChanges) {
    if (!devModeEqual(oldValue, newValue)) {
      throw new ExpressionChangedAfterItHasBeenCheckedException(
          oldValue, newValue, null);
    }
    return false;
  } else {
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
bool mapLooseIdentical/*< V >*/(
    Map<String, dynamic/*= V */ > m1, Map<String, dynamic/*= V */ > m2) {
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

dynamic/*= T */ castByValue/*< T >*/(dynamic input, dynamic/*= T */ value) {
  return (input as dynamic/*= T */);
}

const EMPTY_ARRAY = const [];
const EMPTY_MAP = const {};
dynamic /* (p0: P0) => R */ pureProxy1/*< P0, R >*/(
    dynamic/*= R */ fn(dynamic /* P0 */ p0)) {
  dynamic/*= R */ result;
  var v0;
  v0 = uninitialized;
  return (p0) {
    if (!looseIdentical(v0, p0)) {
      v0 = p0;
      result = fn(p0);
    }
    return result;
  };
}

dynamic /* (p0: P0, p1: P1) => R */ pureProxy2/*< P0, P1, R >*/(
    dynamic/*= R */ fn(dynamic /* P0 */ p0, dynamic /* P1 */ p1)) {
  dynamic/*= R */ result;
  var v0, v1;
  v0 = v1 = uninitialized;
  return (p0, p1) {
    if (!looseIdentical(v0, p0) || !looseIdentical(v1, p1)) {
      v0 = p0;
      v1 = p1;
      result = fn(p0, p1);
    }
    return result;
  };
}

dynamic
    /* (p0: P0, p1: P1,
                                                                               p2: P2) => R */
    pureProxy3/*< P0, P1, P2, R >*/(
        dynamic/*= R */ fn(
            dynamic /* P0 */ p0, dynamic /* P1 */ p1, dynamic /* P2 */ p2)) {
  dynamic/*= R */ result;
  var v0, v1, v2;
  v0 = v1 = v2 = uninitialized;
  return (p0, p1, p2) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2)) {
      v0 = p0;
      v1 = p1;
      v2 = p2;
      result = fn(p0, p1, p2);
    }
    return result;
  };
}

dynamic /* (
    p0: P0, p1: P1, p2: P2, p3: P3) => R */
    pureProxy4/*< P0, P1, P2, P3, R >*/(
        dynamic/*= R */ fn(dynamic /* P0 */ p0, dynamic /* P1 */ p1,
            dynamic /* P2 */ p2, dynamic /* P3 */ p3)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3;
  v0 = v1 = v2 = v3 = uninitialized;
  return (p0, p1, p2, p3) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3)) {
      v0 = p0;
      v1 = p1;
      v2 = p2;
      v3 = p3;
      result = fn(p0, p1, p2, p3);
    }
    return result;
  };
}

dynamic /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4) =>
    R */
    pureProxy5/*< P0, P1, P2, P3, P4, R >*/(
        dynamic/*= R */
        fn(dynamic /* P0 */ p0, dynamic /* P1 */ p1, dynamic /* P2 */ p2,
            dynamic /* P3 */ p3, dynamic /* P4 */ p4)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3, v4;
  v0 = v1 = v2 = v3 = v4 = uninitialized;
  return (p0, p1, p2, p3, p4) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4)) {
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

dynamic
    /* (p0: P0, p1: P1, p2: P2, p3: P3,
                                                                 p4: P4, p5: P5) => R */
    pureProxy6/*< P0, P1, P2, P3, P4, P5, R >*/(
        dynamic/*= R */
        fn(dynamic /* P0 */ p0, dynamic /* P1 */ p1, dynamic /* P2 */ p2,
            dynamic /* P3 */ p3, dynamic /* P4 */ p4, dynamic /* P5 */ p5)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3, v4, v5;
  v0 = v1 = v2 = v3 = v4 = v5 = uninitialized;
  return (p0, p1, p2, p3, p4, p5) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5)) {
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

dynamic /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4, p5: P5, p6: P6) => R */
    pureProxy7/*< P0, P1, P2, P3, P4, P5, P6, R >*/(
        dynamic/*= R */ fn(
            dynamic /* P0 */ p0,
            dynamic /* P1 */ p1,
            dynamic /* P2 */ p2,
            dynamic /* P3 */ p3,
            dynamic /* P4 */ p4,
            dynamic /* P5 */ p5,
            dynamic /* P6 */ p6)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3, v4, v5, v6;
  v0 = v1 = v2 = v3 = v4 = v5 = v6 = uninitialized;
  return (p0, p1, p2, p3, p4, p5, p6) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6)) {
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

dynamic
    /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4, p5: P5, p6: P6, p7: P7) => R */
    pureProxy8/*< P0, P1, P2, P3, P4, P5, P6, P7, R >*/(
        dynamic/*= R */ fn(
            dynamic /* P0 */ p0,
            dynamic /* P1 */ p1,
            dynamic /* P2 */ p2,
            dynamic /* P3 */ p3,
            dynamic /* P4 */ p4,
            dynamic /* P5 */ p5,
            dynamic /* P6 */ p6,
            dynamic /* P7 */ p7)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3, v4, v5, v6, v7;
  v0 = v1 = v2 = v3 = v4 = v5 = v6 = v7 = uninitialized;
  return (p0, p1, p2, p3, p4, p5, p6, p7) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6) ||
        !looseIdentical(v7, p7)) {
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

dynamic /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4, p5: P5, p6: P6, p7: P7, p8: P8) => R */ pureProxy9/*< P0, P1, P2, P3, P4, P5, P6, P7, P8, R >*/(
    dynamic/*= R */ fn(
        dynamic /* P0 */ p0,
        dynamic /* P1 */ p1,
        dynamic /* P2 */ p2,
        dynamic /* P3 */ p3,
        dynamic /* P4 */ p4,
        dynamic /* P5 */ p5,
        dynamic /* P6 */ p6,
        dynamic /* P7 */ p7,
        dynamic /* P8 */ p8)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3, v4, v5, v6, v7, v8;
  v0 = v1 = v2 = v3 = v4 = v5 = v6 = v7 = v8 = uninitialized;
  return (p0, p1, p2, p3, p4, p5, p6, p7, p8) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6) ||
        !looseIdentical(v7, p7) ||
        !looseIdentical(v8, p8)) {
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

dynamic /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4, p5: P5, p6: P6, p7: P7, p8: P8, p9: P9) => R */ pureProxy10/*< P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, R >*/(
    dynamic/*= R */ fn(
        dynamic /* P0 */ p0,
        dynamic /* P1 */ p1,
        dynamic /* P2 */ p2,
        dynamic /* P3 */ p3,
        dynamic /* P4 */ p4,
        dynamic /* P5 */ p5,
        dynamic /* P6 */ p6,
        dynamic /* P7 */ p7,
        dynamic /* P8 */ p8,
        dynamic /* P9 */ p9)) {
  dynamic/*= R */ result;
  var v0, v1, v2, v3, v4, v5, v6, v7, v8, v9;
  v0 = v1 = v2 = v3 = v4 = v5 = v6 = v7 = v8 = v9 = uninitialized;
  return (p0, p1, p2, p3, p4, p5, p6, p7, p8, p9) {
    if (!looseIdentical(v0, p0) ||
        !looseIdentical(v1, p1) ||
        !looseIdentical(v2, p2) ||
        !looseIdentical(v3, p3) ||
        !looseIdentical(v4, p4) ||
        !looseIdentical(v5, p5) ||
        !looseIdentical(v6, p6) ||
        !looseIdentical(v7, p7) ||
        !looseIdentical(v8, p8) ||
        !looseIdentical(v9, p9)) {
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
