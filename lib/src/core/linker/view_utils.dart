library angular2.src.core.linker.view_utils;

import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, Type, stringify, looseIdentical;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "element.dart" show AppElement;
import "exceptions.dart" show ExpressionChangedAfterItHasBeenCheckedException;
import "package:angular2/src/core/change_detection/change_detection.dart"
    show devModeEqual;
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
