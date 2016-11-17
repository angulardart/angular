import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/core/linker/view_type.dart";
import "package:angular2/src/core/render/api.dart" show RenderDebugInfo;
import "package:angular2/src/debug/debug_app_view.dart";

class StaticNodeDebugInfo {
  final List providerTokens;
  final dynamic componentToken;
  final Map<String, dynamic> refTokens;
  const StaticNodeDebugInfo(
      this.providerTokens, this.componentToken, this.refTokens);
}

var _EMPTY_DEBUG_PROVIDERS = const [];
var _EMPTY_REF_TOKENS = <String, dynamic>{};

class DebugContext<T> implements RenderDebugInfo {
  DebugAppView<T> _view;
  num _nodeIndex;
  num _tplRow;
  num _tplCol;

  DebugContext(this._view, this._nodeIndex, this._tplRow, this._tplCol);

  StaticNodeDebugInfo get _staticNodeInfo => _nodeIndex != null
      ? this._view.staticNodeDebugInfos[this._nodeIndex]
      : null;

  T get context => this._view.ctx;

  dynamic get component {
    var staticNodeInfo = _staticNodeInfo;
    if (staticNodeInfo?.componentToken != null) {
      return injector.get(staticNodeInfo.componentToken);
    }
    return null;
  }

  dynamic get componentRenderElement {
    var componentView = this._view;
    while (componentView.declarationViewContainer != null &&
        !identical(componentView.type, ViewType.COMPONENT)) {
      componentView = (componentView.declarationViewContainer.parentView
          as DebugAppView<T>);
    }
    return componentView.declarationViewContainer?.nativeElement;
  }

  Injector get injector => _view.injector(this._nodeIndex);

  dynamic get renderNode {
    if (_nodeIndex != null && _view.allNodes != null) {
      return _view.allNodes[this._nodeIndex];
    }
    return null;
  }

  List<dynamic> get providerTokens {
    var staticNodeInfo = _staticNodeInfo;
    return staticNodeInfo == null
        ? _EMPTY_DEBUG_PROVIDERS
        : staticNodeInfo.providerTokens;
  }

  String get source {
    return '${_view.componentType.templateUrl}:${_tplRow}:${_tplCol}';
  }

  Map<String, String> get locals {
    Map<String, String> varValues = {};

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
