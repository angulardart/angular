library angular2.src.core.linker.view_utils;

import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, Type, stringify, looseIdentical;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "element.dart" show AppElement;
import "exceptions.dart" show ExpressionChangedAfterItHasBeenCheckedException;
import "package:angular2/src/core/change_detection/change_detection.dart"
    show devModeEqual, uninitialized;
import "package:angular2/src/core/di.dart" show Inject, Injectable;
import "package:angular2/src/core/render/api.dart"
    show RootRenderer, RenderComponentType, Renderer;
import "package:angular2/src/core/application_tokens.dart" show APP_ID;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;

@Injectable()
class ViewUtils {
  RootRenderer _renderer;
  String _appId;
  num _nextCompTypeId = 0;
  ViewUtils(this._renderer, @Inject(APP_ID) this._appId) {}
  /**
   * Used by the generated code
   */
  RenderComponentType createRenderComponentType(
      String templateUrl,
      num slotCount,
      ViewEncapsulation encapsulation,
      List<dynamic /* String | List < dynamic > */ > styles) {
    return new RenderComponentType(
        '''${ this . _appId}-${ this . _nextCompTypeId ++}''',
        templateUrl,
        slotCount,
        encapsulation,
        styles);
  }

  /** @internal */
  Renderer renderComponent(RenderComponentType renderComponentType) {
    return this._renderer.renderComponent(renderComponentType);
  }
}

List<dynamic> flattenNestedViewRenderNodes(List<dynamic> nodes) {
  return _flattenNestedViewRenderNodes(nodes, []);
}

List<dynamic> _flattenNestedViewRenderNodes(
    List<dynamic> nodes, List<dynamic> renderNodes) {
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    if (node is AppElement) {
      var appEl = (node as AppElement);
      renderNodes.add(appEl.nativeElement);
      if (isPresent(appEl.nestedViews)) {
        for (var k = 0; k < appEl.nestedViews.length; k++) {
          _flattenNestedViewRenderNodes(
              appEl.nestedViews[k].rootNodesOrAppElements, renderNodes);
        }
      }
    } else {
      renderNodes.add(node);
    }
  }
  return renderNodes;
}

const EMPTY_ARR = const [];
List<List<dynamic>> ensureSlotCount(
    List<List<dynamic>> projectableNodes, num expectedSlotCount) {
  var res;
  if (isBlank(projectableNodes)) {
    res = EMPTY_ARR;
  } else if (projectableNodes.length < expectedSlotCount) {
    var givenSlotCount = projectableNodes.length;
    res = ListWrapper.createFixedSize(expectedSlotCount);
    for (var i = 0; i < expectedSlotCount; i++) {
      res[i] = (i < givenSlotCount) ? projectableNodes[i] : EMPTY_ARR;
    }
  } else {
    res = projectableNodes;
  }
  return res;
}

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

String _toStringWithNull(dynamic v) {
  return v != null ? v.toString() : "";
}

bool checkBinding(bool throwOnChange, dynamic oldValue, dynamic newValue) {
  if (throwOnChange) {
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

bool mapLooseIdentical/*< V >*/(
    Map<String, dynamic/*= V */ > m1, Map<String, dynamic/*= V */ > m2) {
  var k1 = StringMapWrapper.keys(m1);
  var k2 = StringMapWrapper.keys(m2);
  if (k1.length != k2.length) {
    return false;
  }
  var key;
  for (var i = 0; i < k1.length; i++) {
    key = k1[i];
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
    dynamic/*= R */ fn(dynamic/*= P0 */ p0)) {
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
    dynamic/*= R */ fn(dynamic/*= P0 */ p0, dynamic/*= P1 */ p1)) {
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
    pureProxy3/*< P0, P1, P2, R >*/(dynamic/*= R */ fn(dynamic/*= P0 */ p0, dynamic/*= P1 */ p1, dynamic/*= P2 */ p2)) {
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
    pureProxy4/*< P0, P1, P2, P3, R >*/(dynamic/*= R */ fn(dynamic/*= P0 */ p0, dynamic/*= P1 */ p1, dynamic/*= P2 */ p2, dynamic/*= P3 */ p3)) {
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
    pureProxy5/*< P0, P1, P2, P3, P4, R >*/(dynamic/*= R */ fn(dynamic/*= P0 */ p0, dynamic/*= P1 */ p1, dynamic/*= P2 */ p2, dynamic/*= P3 */ p3, dynamic/*= P4 */ p4)) {
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
    pureProxy6/*< P0, P1, P2, P3, P4, P5, R >*/(dynamic/*= R */ fn(dynamic/*= P0 */ p0, dynamic/*= P1 */ p1, dynamic/*= P2 */ p2, dynamic/*= P3 */ p3, dynamic/*= P4 */ p4, dynamic/*= P5 */ p5)) {
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

dynamic /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4, p5: P5, p6: P6) => R */ pureProxy7/*< P0, P1, P2, P3, P4, P5, P6, R >*/(
    dynamic/*= R */ fn(
        dynamic/*= P0 */ p0,
        dynamic/*= P1 */ p1,
        dynamic/*= P2 */ p2,
        dynamic/*= P3 */ p3,
        dynamic/*= P4 */ p4,
        dynamic/*= P5 */ p5,
        dynamic/*= P6 */ p6)) {
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

dynamic /* (p0: P0, p1: P1, p2: P2, p3: P3, p4: P4, p5: P5, p6: P6, p7: P7) => R */ pureProxy8/*< P0, P1, P2, P3, P4, P5, P6, P7, R >*/(
    dynamic/*= R */ fn(
        dynamic/*= P0 */ p0,
        dynamic/*= P1 */ p1,
        dynamic/*= P2 */ p2,
        dynamic/*= P3 */ p3,
        dynamic/*= P4 */ p4,
        dynamic/*= P5 */ p5,
        dynamic/*= P6 */ p6,
        dynamic/*= P7 */ p7)) {
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
        dynamic/*= P0 */ p0,
        dynamic/*= P1 */ p1,
        dynamic/*= P2 */ p2,
        dynamic/*= P3 */ p3,
        dynamic/*= P4 */ p4,
        dynamic/*= P5 */ p5,
        dynamic/*= P6 */ p6,
        dynamic/*= P7 */ p7,
        dynamic/*= P8 */ p8)) {
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
        dynamic/*= P0 */ p0,
        dynamic/*= P1 */ p1,
        dynamic/*= P2 */ p2,
        dynamic/*= P3 */ p3,
        dynamic/*= P4 */ p4,
        dynamic/*= P5 */ p5,
        dynamic/*= P6 */ p6,
        dynamic/*= P7 */ p7,
        dynamic/*= P8 */ p8,
        dynamic/*= P9 */ p9)) {
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
