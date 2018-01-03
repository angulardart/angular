import "package:angular/src/core/di.dart" show Injector;
import "package:angular/src/core/render/api.dart" show RenderDebugInfo;

import "debug_app_view.dart";

class StaticNodeDebugInfo {
  final List providerTokens;
  final dynamic componentToken;
  final Map<String, dynamic> refTokens;
  const StaticNodeDebugInfo(
      this.providerTokens, this.componentToken, this.refTokens);
}

class DebugContext<T> implements RenderDebugInfo {
  DebugAppView<T> _view;
  final int _nodeIndex;
  final int _tplRow;
  final int _tplCol;

  DebugContext(this._view, this._nodeIndex, this._tplRow, this._tplCol);

  StaticNodeDebugInfo get _staticNodeInfo => _nodeIndex != null
      ? this._view.staticNodeDebugInfos[this._nodeIndex]
      : null;

  T get context => this._view.ctx;

  dynamic get component {
    var staticNodeInfo = _staticNodeInfo;
    if (staticNodeInfo?.componentToken != null) {
      // If the component has Visibility.none, the injector will fail to return
      // an instance, so we explicitly return null instead of throwing. This is
      // done to support a common testing pattern where a query is run over
      // every DebugContext in a hierarchy of views to find an instance of a
      // specific component.
      return injector.get(staticNodeInfo.componentToken, null);
    }
    return null;
  }

  Injector get injector => _view.injector(this._nodeIndex);

  dynamic get renderNode {
    if (_nodeIndex != null && _view.allNodes != null) {
      return _view.allNodes[this._nodeIndex];
    }
    return _view.rootEl;
  }

  List<dynamic> get providerTokens {
    var staticNodeInfo = _staticNodeInfo;
    return staticNodeInfo == null
        ? const <dynamic>[]
        : staticNodeInfo.providerTokens;
  }

  String get source {
    var componentType = _view.componentType;
    // If Host crashes in View0 initialization, show class type instead of
    // componentType.
    return componentType == null
        ? '$_view'
        : '${componentType.templateUrl}:$_tplRow:$_tplCol';
  }

  Map<String, dynamic> get locals {
    Map<String, dynamic> varValues = {};

    // There are many instances of:
    // StaticNodeDebugInfo(const [],null,const <String, dynamic>{}),
    // When these are compiled, they are written out as null inside
    // nodeDebugInfos array to preserve order, so we skip null values.

    // TODO(tbosch): right now, the semantics of debugNode.locals are
    // that it contains the variables of all elements, not just
    // the given one. We preserve this for now to not have a breaking
    // change, but should change this later!
    var debugInfos = _view.staticNodeDebugInfos;
    int infoCount = debugInfos.length;
    for (int nodeIndex = 0; nodeIndex < infoCount; nodeIndex++) {
      StaticNodeDebugInfo staticNodeInfo = debugInfos[nodeIndex];
      if (staticNodeInfo == null) continue;
      var refs = staticNodeInfo.refTokens;
      refs.forEach((String refName, refToken) {
        var varValue;
        if (refToken == null) {
          varValue = _view.allNodes != null ? _view.allNodes[nodeIndex] : null;
        } else {
          varValue = _view.injectorGet(refToken, nodeIndex, null);
        }
        varValues[refName] = varValue;
      });
    }
    _view.locals?.forEach((String localName, localValue) {
      varValues[localName] = localValue;
    });
    return varValues;
  }
}
