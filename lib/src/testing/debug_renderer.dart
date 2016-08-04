import "package:angular2/src/testing/debug_node.dart"
    show
        DebugNode,
        DebugElement,
        EventListener,
        getDebugNode,
        indexDebugNode,
        inspectNativeElement,
        removeDebugNodeFromIndex;

import 'package:angular2/src/animate/animation_builder.dart'
    show AnimationBuilder;
import 'package:angular2/src/core/di.dart' show Inject, Injectable;
import "package:angular2/src/core/render/api.dart"
    show Renderer, RootRenderer, RenderComponentType, RenderDebugInfo;
import '../platform/dom/dom_tokens.dart' show DOCUMENT;
import '../platform/dom/dom_renderer.dart' show DomRenderer, DomRootRenderer;
import '../platform/dom/events/event_manager.dart' show EventManager;
import '../platform/dom/shared_styles_host.dart' show DomSharedStylesHost;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;

const INSPECT_GLOBAL_NAME = "ng.probe";

/// Returns a [DebugElement] for the given native DOM element, or
/// null if the given native element does not have an Angular view associated
/// with it.

@Injectable()
class DebugDomRootRenderer implements DomRootRenderer {
  static bool isDirty = false;
  dynamic document;
  EventManager eventManager;
  DomSharedStylesHost sharedStylesHost;
  AnimationBuilder animate;
  var _registeredComponents = <String, DomRenderer>{};

  DebugDomRootRenderer(@Inject(DOCUMENT) this.document, this.eventManager,
      this.sharedStylesHost, this.animate) {
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

  dynamic createTemplateAnchor(
      dynamic parentElement, RenderDebugInfo debugInfo) {
    var comment = super.createTemplateAnchor(parentElement, debugInfo);
    var debugEl =
        new DebugNode(comment, getDebugNode(parentElement), debugInfo);
    indexDebugNode(debugEl);
    return comment;
  }

  dynamic createText(
      dynamic parentElement, String value, RenderDebugInfo debugInfo) {
    var text = super.createText(parentElement, value, debugInfo);
    var debugEl = new DebugNode(text, getDebugNode(parentElement), debugInfo);
    indexDebugNode(debugEl);
    return text;
  }

  projectNodes(dynamic parentElement, List<dynamic> nodes) {
    var debugParent = getDebugNode(parentElement);
    if (debugParent != null && debugParent is DebugElement) {
      var debugElement = debugParent;
      nodes.forEach((node) {
        debugElement.addChild(getDebugNode(node));
      });
    }
    super.projectNodes(parentElement, nodes);
  }

  attachViewAfter(dynamic node, List<dynamic> viewRootNodes) {
    var debugNode = getDebugNode(node);
    if (debugNode != null) {
      var debugParent = debugNode.parent;
      if (viewRootNodes.length > 0 && debugParent != null) {
        List<DebugNode> debugViewRootNodes = [];
        viewRootNodes.forEach(
            (rootNode) => debugViewRootNodes.add(getDebugNode(rootNode)));
        debugParent.insertChildrenAfter(debugNode, debugViewRootNodes);
      }
    }
    super.attachViewAfter(node, viewRootNodes);
  }

  detachView(List<dynamic> viewRootNodes) {
    viewRootNodes.forEach((node) {
      var debugNode = getDebugNode(node);
      if (debugNode != null && debugNode.parent != null) {
        debugNode.parent.removeChild(debugNode);
      }
    });
    super.detachView(viewRootNodes);
  }

  destroyView(dynamic hostElement, List<dynamic> viewAllNodes) {
    viewAllNodes.forEach((node) {
      removeDebugNodeFromIndex(getDebugNode(node));
    });
    super.destroyView(hostElement, viewAllNodes);
  }

  Function listen(dynamic renderElement, String name, Function callback) {
    var debugEl = getDebugNode(renderElement);
    if (debugEl != null) {
      debugEl.listeners.add(new EventListener(name, callback));
    }
    return super.listen(renderElement, name, callback);
  }

  setElementProperty(
      dynamic renderElement, String propertyName, dynamic propertyValue) {
    var debugEl = getDebugNode(renderElement);
    if (debugEl != null && debugEl is DebugElement) {
      debugEl.properties[propertyName] = propertyValue;
    }
    super.setElementProperty(renderElement, propertyName, propertyValue);
  }

  setElementAttribute(
      dynamic renderElement, String attributeName, String attributeValue) {
    var debugEl = getDebugNode(renderElement);
    if (debugEl != null && debugEl is DebugElement) {
      debugEl.attributes[attributeName] = attributeValue;
    }
    super.setElementAttribute(renderElement, attributeName, attributeValue);
  }
}
