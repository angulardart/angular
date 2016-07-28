import "package:angular2/src/core/debug/debug_node.dart"
    show
        DebugNode,
        DebugElement,
        EventListener,
        getDebugNode,
        indexDebugNode,
        removeDebugNodeFromIndex;
import "package:angular2/src/core/render/api.dart"
    show Renderer, RootRenderer, RenderComponentType, RenderDebugInfo;
import "package:angular2/src/facade/lang.dart" show isPresent;

class DebugDomRootRenderer implements RootRenderer {
  RootRenderer _delegate;
  DebugDomRootRenderer(this._delegate) {}
  Renderer renderComponent(RenderComponentType componentProto) {
    return new DebugDomRenderer(this._delegate.renderComponent(componentProto));
  }
}

class DebugDomRenderer implements Renderer {
  Renderer _delegate;
  DebugDomRenderer(this._delegate) {}
  dynamic selectRootElement(dynamic /* String | dynamic */ selectorOrNode,
      RenderDebugInfo debugInfo) {
    var nativeEl = this._delegate.selectRootElement(selectorOrNode, debugInfo);
    var debugEl = new DebugElement(nativeEl, null, debugInfo);
    indexDebugNode(debugEl);
    return nativeEl;
  }

  dynamic createElement(
      dynamic parentElement, String name, RenderDebugInfo debugInfo) {
    var nativeEl = this._delegate.createElement(parentElement, name, debugInfo);
    var debugEl =
        new DebugElement(nativeEl, getDebugNode(parentElement), debugInfo);
    debugEl.name = name;
    indexDebugNode(debugEl);
    return nativeEl;
  }

  dynamic createViewRoot(dynamic hostElement) {
    return this._delegate.createViewRoot(hostElement);
  }

  dynamic createTemplateAnchor(
      dynamic parentElement, RenderDebugInfo debugInfo) {
    var comment = this._delegate.createTemplateAnchor(parentElement, debugInfo);
    var debugEl =
        new DebugNode(comment, getDebugNode(parentElement), debugInfo);
    indexDebugNode(debugEl);
    return comment;
  }

  dynamic createText(
      dynamic parentElement, String value, RenderDebugInfo debugInfo) {
    var text = this._delegate.createText(parentElement, value, debugInfo);
    var debugEl = new DebugNode(text, getDebugNode(parentElement), debugInfo);
    indexDebugNode(debugEl);
    return text;
  }

  projectNodes(dynamic parentElement, List<dynamic> nodes) {
    var debugParent = getDebugNode(parentElement);
    if (isPresent(debugParent) && debugParent is DebugElement) {
      var debugElement = debugParent;
      nodes.forEach((node) {
        debugElement.addChild(getDebugNode(node));
      });
    }
    this._delegate.projectNodes(parentElement, nodes);
  }

  attachViewAfter(dynamic node, List<dynamic> viewRootNodes) {
    var debugNode = getDebugNode(node);
    if (isPresent(debugNode)) {
      var debugParent = debugNode.parent;
      if (viewRootNodes.length > 0 && isPresent(debugParent)) {
        List<DebugNode> debugViewRootNodes = [];
        viewRootNodes.forEach(
            (rootNode) => debugViewRootNodes.add(getDebugNode(rootNode)));
        debugParent.insertChildrenAfter(debugNode, debugViewRootNodes);
      }
    }
    this._delegate.attachViewAfter(node, viewRootNodes);
  }

  detachView(List<dynamic> viewRootNodes) {
    viewRootNodes.forEach((node) {
      var debugNode = getDebugNode(node);
      if (isPresent(debugNode) && isPresent(debugNode.parent)) {
        debugNode.parent.removeChild(debugNode);
      }
    });
    this._delegate.detachView(viewRootNodes);
  }

  destroyView(dynamic hostElement, List<dynamic> viewAllNodes) {
    viewAllNodes.forEach((node) {
      removeDebugNodeFromIndex(getDebugNode(node));
    });
    this._delegate.destroyView(hostElement, viewAllNodes);
  }

  Function listen(dynamic renderElement, String name, Function callback) {
    var debugEl = getDebugNode(renderElement);
    if (isPresent(debugEl)) {
      debugEl.listeners.add(new EventListener(name, callback));
    }
    return this._delegate.listen(renderElement, name, callback);
  }

  Function listenGlobal(String target, String name, Function callback) {
    return this._delegate.listenGlobal(target, name, callback);
  }

  setElementProperty(
      dynamic renderElement, String propertyName, dynamic propertyValue) {
    var debugEl = getDebugNode(renderElement);
    if (isPresent(debugEl) && debugEl is DebugElement) {
      debugEl.properties[propertyName] = propertyValue;
    }
    this
        ._delegate
        .setElementProperty(renderElement, propertyName, propertyValue);
  }

  setElementAttribute(
      dynamic renderElement, String attributeName, String attributeValue) {
    var debugEl = getDebugNode(renderElement);
    if (isPresent(debugEl) && debugEl is DebugElement) {
      debugEl.attributes[attributeName] = attributeValue;
    }
    this
        ._delegate
        .setElementAttribute(renderElement, attributeName, attributeValue);
  }

  setBindingDebugInfo(
      dynamic renderElement, String propertyName, String propertyValue) {
    this
        ._delegate
        .setBindingDebugInfo(renderElement, propertyName, propertyValue);
  }

  setElementClass(dynamic renderElement, String className, bool isAdd) {
    this._delegate.setElementClass(renderElement, className, isAdd);
  }

  setElementStyle(dynamic renderElement, String styleName, String styleValue) {
    this._delegate.setElementStyle(renderElement, styleName, styleValue);
  }

  setText(dynamic renderNode, String text) {
    this._delegate.setText(renderNode, text);
  }
}
