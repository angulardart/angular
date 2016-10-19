import 'package:angular2/src/core/di.dart' show Inject, Injectable;
import "package:angular2/src/core/render/api.dart"
    show Renderer, RootRenderer, RenderComponentType, RenderDebugInfo;
import "package:angular2/src/debug/debug_node.dart"
    show
        DebugNode,
        DebugElement,
        EventListener,
        getDebugNode,
        indexDebugNode,
        inspectNativeElement,
        removeDebugNodeFromIndex;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;

import '../platform/dom/dom_renderer.dart' show DomRenderer, DomRootRenderer;
import '../platform/dom/dom_tokens.dart' show DOCUMENT;
import '../platform/dom/events/event_manager.dart' show EventManager;

const INSPECT_GLOBAL_NAME = "ng.probe";

/// Returns a [DebugElement] for the given native DOM element, or
/// null if the given native element does not have an Angular view associated
/// with it.

@Injectable()
class DebugDomRootRenderer implements DomRootRenderer {
  static bool isDirty = false;
  dynamic document;
  EventManager eventManager;
  var _registeredComponents = <String, DomRenderer>{};

  DebugDomRootRenderer(@Inject(DOCUMENT) this.document, this.eventManager) {
    DOM.setGlobalVar(INSPECT_GLOBAL_NAME, inspectNativeElement);
  }

  Renderer renderComponent(RenderComponentType componentProto) {
    var renderer = this._registeredComponents[componentProto.id];
    if (renderer == null) {
      renderer = new DebugDomRenderer(this, componentProto);
      this._registeredComponents[componentProto.id] = renderer;
    }
    return renderer;
  }
}

@Deprecated('Use dart:html apis')
class DebugDomRenderer extends DomRenderer {
  DebugDomRenderer(
      RootRenderer rootRenderer, RenderComponentType componentProto)
      : super(rootRenderer, componentProto);

  dynamic selectRootElement(dynamic /* String | dynamic */ selectorOrNode,
      RenderDebugInfo debugInfo) {
    var nativeEl = super.selectRootElement(selectorOrNode, debugInfo);
    var debugEl = new DebugElement(nativeEl, null, debugInfo);
    indexDebugNode(debugEl);
    return nativeEl;
  }

  dynamic createElement(
      dynamic parentElement, String name, RenderDebugInfo debugInfo) {
    var nativeEl = super.createElement(parentElement, name, debugInfo);
    var debugEl =
        new DebugElement(nativeEl, getDebugNode(parentElement), debugInfo);
    debugEl.name = name;
    indexDebugNode(debugEl);
    return nativeEl;
  }

  void attachViewAfter(dynamic node, List<dynamic> viewRootNodes) {
    var debugNode = getDebugNode(node);
    if (debugNode != null) {
      var debugParent = debugNode?.parent;
      if (viewRootNodes.length > 0 && debugParent != null) {
        List<DebugNode> debugViewRootNodes = [];
        int rootNodeCount = viewRootNodes.length;
        for (int n = 0; n < rootNodeCount; n++) {
          var debugNode = getDebugNode(viewRootNodes[n]);
          if (debugNode == null) continue;
          debugViewRootNodes.add(debugNode);
        }
        debugParent.insertChildrenAfter(debugNode, debugViewRootNodes);
      }
    }
    super.attachViewAfter(node, viewRootNodes);
  }

  void detachView(List<dynamic> viewRootNodes) {
    viewRootNodes.forEach((node) {
      var debugNode = getDebugNode(node);
      if (debugNode != null && debugNode.parent != null) {
        debugNode.parent.removeChild(debugNode);
      }
    });
    super.detachView(viewRootNodes);
  }

  void destroyView(dynamic hostElement, List<dynamic> viewAllNodes) {
    int nodeCount = viewAllNodes.length;
    for (int i = 0; i < nodeCount; i++) {
      var debugNode = getDebugNode(viewAllNodes[i]);
      if (debugNode == null) continue;
      removeDebugNodeFromIndex(debugNode);
    }
    super.destroyView(hostElement, viewAllNodes);
  }

  Function listen(dynamic renderElement, String name, Function callback) {
    var debugEl = getDebugNode(renderElement);
    if (debugEl != null) {
      debugEl.listeners.add(new EventListener(name, callback));
    }
    return super.listen(renderElement, name, callback);
  }

  void setElementProperty(
      dynamic renderElement, String propertyName, dynamic propertyValue) {
    var debugEl = getDebugNode(renderElement);
    if (debugEl != null && debugEl is DebugElement) {
      debugEl.properties[propertyName] = propertyValue;
    }
    super.setElementProperty(renderElement, propertyName, propertyValue);
  }
}
