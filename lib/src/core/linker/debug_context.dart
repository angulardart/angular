import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/core/render/api.dart" show RenderDebugInfo;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;

import "view.dart" show DebugAppView;
import "view_type.dart" show ViewType;

class StaticNodeDebugInfo {
  final List<dynamic> providerTokens;
  final dynamic componentToken;
  final Map<String, dynamic> refTokens;
  const StaticNodeDebugInfo(
      this.providerTokens, this.componentToken, this.refTokens);
}

class DebugContext implements RenderDebugInfo {
  DebugAppView<dynamic> _view;
  num _nodeIndex;
  num _tplRow;
  num _tplCol;
  DebugContext(this._view, this._nodeIndex, this._tplRow, this._tplCol) {}
  StaticNodeDebugInfo get _staticNodeInfo {
    return isPresent(this._nodeIndex)
        ? this._view.staticNodeDebugInfos[this._nodeIndex]
        : null;
  }

  get context {
    return this._view.context;
  }

  get component {
    var staticNodeInfo = this._staticNodeInfo;
    if (isPresent(staticNodeInfo) && isPresent(staticNodeInfo.componentToken)) {
      return this.injector.get(staticNodeInfo.componentToken);
    }
    return null;
  }

  get componentRenderElement {
    var componentView = this._view;
    while (isPresent(componentView.declarationAppElement) &&
        !identical(componentView.type, ViewType.COMPONENT)) {
      componentView = (componentView.declarationAppElement.parentView
          as DebugAppView<dynamic>);
    }
    return isPresent(componentView.declarationAppElement)
        ? componentView.declarationAppElement.nativeElement
        : null;
  }

  Injector get injector {
    return this._view.injector(this._nodeIndex);
  }

  dynamic get renderNode {
    if (isPresent(this._nodeIndex) && isPresent(this._view.allNodes)) {
      return this._view.allNodes[this._nodeIndex];
    } else {
      return null;
    }
  }

  List<dynamic> get providerTokens {
    var staticNodeInfo = this._staticNodeInfo;
    return isPresent(staticNodeInfo) ? staticNodeInfo.providerTokens : null;
  }

  String get source {
    return '${_view.componentType.templateUrl}:${_tplRow}:${_tplCol}';
  }

  Map<String, String> get locals {
    Map<String, String> varValues = {};
    // TODO(tbosch): right now, the semantics of debugNode.locals are
    // that it contains the variables of all elements, not just
    // the given one. We preserve this for now to not have a breaking
    // change, but should change this later!
    ListWrapper.forEachWithIndex(this._view.staticNodeDebugInfos,
        (StaticNodeDebugInfo staticNodeInfo, num nodeIndex) {
      var refs = staticNodeInfo.refTokens;
      StringMapWrapper.forEach(refs, (refToken, refName) {
        var varValue;
        if (isBlank(refToken)) {
          varValue = isPresent(this._view.allNodes)
              ? this._view.allNodes[nodeIndex]
              : null;
        } else {
          varValue = this._view.injectorGet(refToken, nodeIndex, null);
        }
        varValues[refName] = varValue;
      });
    });
    StringMapWrapper.forEach(this._view.locals, (localValue, localName) {
      varValues[localName] = localValue;
    });
    return varValues;
  }
}
