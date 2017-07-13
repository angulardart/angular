import "package:angular/src/core/application_ref.dart" show ApplicationRef;
import "package:angular/src/core/di.dart" show Injector;
import "package:angular/src/core/render/api.dart" show RenderDebugInfo;
import "package:angular/src/core/zone/ng_zone.dart" show NgZone;

export "by.dart";

typedef bool Predicate<T>(T item);

class DebugNode {
  final RenderDebugInfo _debugInfo;
  dynamic nativeNode;
  DebugElement parent;
  DebugNode(dynamic nativeNode, DebugNode parent, this._debugInfo) {
    this.nativeNode = nativeNode;
    if (parent != null && parent is DebugElement) {
      parent.addChild(this);
    } else {
      this.parent = null;
    }
  }
  Injector get injector => _debugInfo?.injector;

  dynamic get componentInstance => _debugInfo?.component;

  Map<String, dynamic> get locals => _debugInfo?.locals;

  List<dynamic> get providerTokens => _debugInfo?.providerTokens;

  String get source => _debugInfo?.source;

  dynamic inject(dynamic token) => injector.get(token);

  // Provide [ApplicationRef] for browser extensions.
  dynamic get applicationRef => injector.get(ApplicationRef);

  // Provide [NgZone] for browser extensions.
  dynamic get zone => injector.get(NgZone);

  dynamic getLocal(String name) => locals[name];
}

class DebugElement extends DebugNode {
  String name;
  Map<String, dynamic> properties;
  List<DebugNode> childNodes;
  dynamic nativeElement;

  DebugElement(dynamic nativeNode, dynamic parent, RenderDebugInfo _debugInfo)
      : super(nativeNode, parent, _debugInfo) {
    this.properties = {};
    this.childNodes = [];
    this.nativeElement = nativeNode;
  }

  void addChild(DebugNode child) {
    if (child == null) return;
    this.childNodes.add(child);
    child.parent = this;
  }

  void removeChild(DebugNode child) {
    int childIndex = childNodes.indexOf(child);
    if (childIndex != -1) {
      child.parent = null;
      childNodes.removeAt(childIndex);
    }
  }

  Map get attributes => nativeElement.attributes;

  void insertChildrenAfter(DebugNode child, List<DebugNode> newChildren) {
    var siblingIndex = this.childNodes.indexOf(child);
    if (!identical(siblingIndex, -1)) {
      var previousChildren = childNodes.sublist(0, siblingIndex + 1);
      this.childNodes = new List.from(previousChildren)
        ..addAll(newChildren)
        ..addAll(childNodes.sublist(siblingIndex + 1));
      for (var i = 0; i < newChildren.length; ++i) {
        var newChild = newChildren[i];
        newChild.parent?.removeChild(newChild);
        newChild.parent = this;
      }
    }
  }

  DebugElement query(Predicate<DebugElement> predicate) {
    var results = queryAll(predicate);
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
    for (var node in childNodes) {
      if (node is DebugElement) {
        children.add(node);
      }
    }
    return children;
  }
}

dynamic asNativeElements(List<DebugElement> debugEls) {
  return debugEls.map((el) => el.nativeElement).toList();
}

void _queryElementChildren(DebugElement element,
    Predicate<DebugElement> predicate, List<DebugElement> matches) {
  for (var node in element.childNodes) {
    if (node is DebugElement) {
      if (predicate(node)) {
        matches.add(node);
      }
      _queryElementChildren(node, predicate, matches);
    }
  }
}

void _queryNodeChildren(DebugNode parentNode, Predicate<DebugNode> predicate,
    List<DebugNode> matches) {
  if (parentNode is DebugElement) {
    for (var node in parentNode.childNodes) {
      if (predicate(node)) {
        matches.add(node);
      }
      if (node is DebugElement) {
        _queryNodeChildren(node, predicate, matches);
      }
    }
  }
}

// Need to keep the nodes in a global Map so that multiple angular apps are supported.
var _nativeNodeToDebugNode = new Map<dynamic, DebugNode>();
DebugNode getDebugNode(dynamic nativeNode) {
  return _nativeNodeToDebugNode[nativeNode];
}

List<DebugNode> getAllDebugNodes() => _nativeNodeToDebugNode.values.toList();

void indexDebugNode(DebugNode node) {
  _nativeNodeToDebugNode[node.nativeNode] = node;
}

void removeDebugNodeFromIndex(DebugNode node) {
  (_nativeNodeToDebugNode.containsKey(node.nativeNode) &&
      (_nativeNodeToDebugNode.remove(node.nativeNode) != null || true));
}

DebugNode inspectNativeElement(element) {
  return getDebugNode(element);
}
