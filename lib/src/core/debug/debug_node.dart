import "package:angular2/src/core/di.dart" show Injector;
import "package:angular2/src/core/render/api.dart" show RenderDebugInfo;
import "package:angular2/src/facade/collection.dart" show Predicate;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, MapWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent;

class EventListener {
  String name;
  Function callback;
  EventListener(this.name, this.callback) {}
}

class DebugNode {
  RenderDebugInfo _debugInfo;
  dynamic nativeNode;
  List<EventListener> listeners;
  DebugElement parent;
  DebugNode(dynamic nativeNode, DebugNode parent, this._debugInfo) {
    this.nativeNode = nativeNode;
    if (isPresent(parent) && parent is DebugElement) {
      parent.addChild(this);
    } else {
      this.parent = null;
    }
    this.listeners = [];
  }
  Injector get injector {
    return isPresent(this._debugInfo) ? this._debugInfo.injector : null;
  }

  dynamic get componentInstance {
    return isPresent(this._debugInfo) ? this._debugInfo.component : null;
  }

  Map<String, dynamic> get locals {
    return isPresent(this._debugInfo) ? this._debugInfo.locals : null;
  }

  List<dynamic> get providerTokens {
    return isPresent(this._debugInfo) ? this._debugInfo.providerTokens : null;
  }

  String get source {
    return isPresent(this._debugInfo) ? this._debugInfo.source : null;
  }

  dynamic inject(dynamic token) {
    return this.injector.get(token);
  }

  dynamic getLocal(String name) {
    return this.locals[name];
  }
}

class DebugElement extends DebugNode {
  String name;
  Map<String, dynamic> properties;
  Map<String, String> attributes;
  List<DebugNode> childNodes;
  dynamic nativeElement;
  DebugElement(dynamic nativeNode, dynamic parent, RenderDebugInfo _debugInfo)
      : super(nativeNode, parent, _debugInfo) {
    /* super call moved to initializer */;
    this.properties = {};
    this.attributes = {};
    this.childNodes = [];
    this.nativeElement = nativeNode;
  }
  addChild(DebugNode child) {
    if (isPresent(child)) {
      this.childNodes.add(child);
      child.parent = this;
    }
  }

  removeChild(DebugNode child) {
    var childIndex = this.childNodes.indexOf(child);
    if (!identical(childIndex, -1)) {
      child.parent = null;
      ListWrapper.splice(this.childNodes, childIndex, 1);
    }
  }

  insertChildrenAfter(DebugNode child, List<DebugNode> newChildren) {
    var siblingIndex = this.childNodes.indexOf(child);
    if (!identical(siblingIndex, -1)) {
      var previousChildren =
          ListWrapper.slice(this.childNodes, 0, siblingIndex + 1);
      var nextChildren = ListWrapper.slice(this.childNodes, siblingIndex + 1);
      this.childNodes = ListWrapper.concat(
          ListWrapper.concat(previousChildren, newChildren), nextChildren);
      for (var i = 0; i < newChildren.length; ++i) {
        var newChild = newChildren[i];
        if (isPresent(newChild.parent)) {
          newChild.parent.removeChild(newChild);
        }
        newChild.parent = this;
      }
    }
  }

  DebugElement query(Predicate<DebugElement> predicate) {
    var results = this.queryAll(predicate);
    return results.length > 0 ? results[0] : null;
  }

  List<DebugElement> queryAll(Predicate<DebugElement> predicate) {
    List<DebugElement> matches = [];
    _queryElementChildren(this, predicate, matches);
    return matches;
  }

  List<DebugNode> queryAllNodes(Predicate<DebugNode> predicate) {
    List<DebugNode> matches = [];
    _queryNodeChildren(this, predicate, matches);
    return matches;
  }

  List<DebugElement> get children {
    List<DebugElement> children = [];
    this.childNodes.forEach((node) {
      if (node is DebugElement) {
        children.add(node);
      }
    });
    return children;
  }

  triggerEventHandler(String eventName, dynamic eventObj) {
    this.listeners.forEach((listener) {
      if (listener.name == eventName) {
        listener.callback(eventObj);
      }
    });
  }
}

dynamic asNativeElements(List<DebugElement> debugEls) {
  return debugEls.map((el) => el.nativeElement).toList();
}

_queryElementChildren(DebugElement element, Predicate<DebugElement> predicate,
    List<DebugElement> matches) {
  element.childNodes.forEach((node) {
    if (node is DebugElement) {
      if (predicate(node)) {
        matches.add(node);
      }
      _queryElementChildren(node, predicate, matches);
    }
  });
}

_queryNodeChildren(DebugNode parentNode, Predicate<DebugNode> predicate,
    List<DebugNode> matches) {
  if (parentNode is DebugElement) {
    parentNode.childNodes.forEach((node) {
      if (predicate(node)) {
        matches.add(node);
      }
      if (node is DebugElement) {
        _queryNodeChildren(node, predicate, matches);
      }
    });
  }
}

// Need to keep the nodes in a global Map so that multiple angular apps are supported.
var _nativeNodeToDebugNode = new Map<dynamic, DebugNode>();
DebugNode getDebugNode(dynamic nativeNode) {
  return _nativeNodeToDebugNode[nativeNode];
}

List<DebugNode> getAllDebugNodes() {
  return MapWrapper.values(_nativeNodeToDebugNode);
}

indexDebugNode(DebugNode node) {
  _nativeNodeToDebugNode[node.nativeNode] = node;
}

removeDebugNodeFromIndex(DebugNode node) {
  (_nativeNodeToDebugNode.containsKey(node.nativeNode) &&
      (_nativeNodeToDebugNode.remove(node.nativeNode) != null || true));
}
