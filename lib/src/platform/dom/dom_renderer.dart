import 'package:angular2/src/compiler/view_compiler/view_compiler_utils.dart'
    show TEMPLATE_COMMENT_TEXT, TEMPLATE_BINDINGS_EXP;
import 'package:angular2/src/core/di.dart' show Inject, Injectable;
import 'package:angular2/src/core/metadata.dart' show ViewEncapsulation;
import 'package:angular2/src/core/render/api.dart'
    show
        Renderer,
        RootRenderer,
        RenderComponentType,
        RenderDebugInfo,
        sharedStylesHost;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import 'package:angular2/src/facade/lang.dart' show Json;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;

import 'dom_tokens.dart' show DOCUMENT;
import 'events/event_manager.dart' show EventManager;

const NAMESPACE_URIS = const {
  'xlink': 'http://www.w3.org/1999/xlink',
  'svg': 'http://www.w3.org/2000/svg',
  'xhtml': 'http://www.w3.org/1999/xhtml'
};

@Injectable()
class DomRootRenderer implements RootRenderer {
  static bool isDirty = false;
  dynamic document;
  EventManager eventManager;
  var _registeredComponents = <String, DomRenderer>{};

  DomRootRenderer(@Inject(DOCUMENT) this.document, this.eventManager);

  Renderer renderComponent(RenderComponentType componentProto) {
    var renderer = this._registeredComponents[componentProto.id];
    if (renderer == null) {
      renderer = new DomRenderer(this, componentProto);
      this._registeredComponents[componentProto.id] = renderer;
    }
    return renderer;
  }
}

@Deprecated('Use dart:html apis')
class DomRenderer implements Renderer {
  DomRootRenderer _rootRenderer;
  RenderComponentType componentProto;

  DomRenderer(@Inject(RootRenderer) this._rootRenderer, this.componentProto) {
    componentProto.shimStyles(sharedStylesHost);
  }

  dynamic selectRootElement(dynamic /* String | dynamic */ selectorOrNode,
      RenderDebugInfo debugInfo) {
    var el;
    if (selectorOrNode is String) {
      el = DOM.querySelector(this._rootRenderer.document, selectorOrNode);
      if (el == null) {
        throw new BaseException(
            'The selector "${selectorOrNode}" did not match any elements');
      }
    } else {
      el = selectorOrNode;
    }
    DOM.clearNodes(el);
    return el;
  }

  dynamic createElement(
      dynamic parent, String name, RenderDebugInfo debugInfo) {
    var nsAndName = splitNamespace(name);
    var el = nsAndName[0] != null
        ? DOM.createElementNS(NAMESPACE_URIS[nsAndName[0]], nsAndName[1])
        : DOM.createElement(nsAndName[1]);
    if (componentProto.contentAttr != null) {
      DOM.setAttribute(el, componentProto.contentAttr, '');
    }
    if (parent != null) {
      DOM.appendChild(parent, el);
    }
    DomRootRenderer.isDirty = true;
    return el;
  }

  void attachViewAfter(dynamic node, List<dynamic> viewRootNodes) {
    moveNodesAfterSibling(node, viewRootNodes);
    DomRootRenderer.isDirty = true;
  }

  void detachView(List<dynamic> viewRootNodes) {
    int len = viewRootNodes.length;
    for (var i = 0; i < len; i++) {
      var node = viewRootNodes[i];
      DOM.remove(node);
      DomRootRenderer.isDirty = true;
    }
  }

  void destroyView(dynamic hostElement, List<dynamic> viewAllNodes) {
    if (componentProto.encapsulation == ViewEncapsulation.Native &&
        hostElement != null) {
      sharedStylesHost.removeHost(DOM.getShadowRoot(hostElement));
      DomRootRenderer.isDirty = true;
    }
  }

  Function listen(dynamic renderElement, String name, Function callback) {
    return _rootRenderer.eventManager.addEventListener(
        renderElement, name, decoratePreventDefault(callback));
  }

  void setElementProperty(
      dynamic renderElement, String propertyName, dynamic propertyValue) {
    DOM.setProperty(renderElement, propertyName, propertyValue);
    DomRootRenderer.isDirty = true;
  }

  @Deprecated("Use dart:html Element attributes and setAttribute.")
  void setElementAttribute(
      dynamic renderElement, String attributeName, String attributeValue) {
    _setAttr(renderElement, attributeName, attributeValue);
  }

  void setBindingDebugInfo(
      dynamic renderElement, String propertyName, String propertyValue) {
    if (DOM.isCommentNode(renderElement)) {
      var existingBindings = TEMPLATE_BINDINGS_EXP.firstMatch(
          DOM.getText(renderElement).replaceAll(new RegExp(r'\n'), ''));
      var parsedBindings = Json.parse(existingBindings[1]);
      parsedBindings[propertyName] = propertyValue;
      DOM.setText(
          renderElement,
          TEMPLATE_COMMENT_TEXT.replaceFirst(
              '{}', Json.stringify(parsedBindings)));
    } else {
      _setAttr(renderElement, propertyName, propertyValue);
    }
  }

  // TODO: deprecate after setBindingInfo is refactored.
  void _setAttr(
      dynamic renderElement, String attributeName, String attributeValue) {
    var attrNs;
    var nsAndName = splitNamespace(attributeName);
    if (nsAndName[0] != null) {
      attributeName = nsAndName[0] + ':' + nsAndName[1];
      attrNs = NAMESPACE_URIS[nsAndName[0]];
    }
    if (attributeValue != null) {
      if (attrNs != null) {
        DOM.setAttributeNS(
            renderElement, attrNs, attributeName, attributeValue);
      } else {
        DOM.setAttribute(renderElement, attributeName, attributeValue);
      }
    } else {
      if (attrNs != null) {
        DOM.removeAttributeNS(renderElement, attrNs, nsAndName[1]);
      } else {
        DOM.removeAttribute(renderElement, attributeName);
      }
    }
    DomRootRenderer.isDirty = true;
  }

  void setElementClass(dynamic renderElement, String className, bool isAdd) {
    if (isAdd) {
      DOM.addClass(renderElement, className);
    } else {
      DOM.removeClass(renderElement, className);
    }
    DomRootRenderer.isDirty = true;
  }

  @Deprecated("Use dart:html .style instead")
  void setElementStyle(
      dynamic renderElement, String styleName, String styleValue) {
    if (styleValue != null) {
      DOM.setStyle(renderElement, styleName, styleValue);
    } else {
      DOM.removeStyle(renderElement, styleName);
    }
    DomRootRenderer.isDirty = true;
  }

  void setText(dynamic renderNode, String text) {
    DOM.setText(renderNode, text);
    DomRootRenderer.isDirty = true;
  }
}

void moveNodesAfterSibling(sibling, nodes) {
  var parent = DOM.parentElement(sibling);
  if (nodes.isNotEmpty && parent != null) {
    var nextSibling = DOM.nextSibling(sibling);
    int len = nodes.length;
    if (nextSibling != null) {
      for (var i = 0; i < len; i++) {
        DOM.insertBefore(nextSibling, nodes[i]);
      }
    } else {
      for (var i = 0; i < len; i++) {
        DOM.appendChild(parent, nodes[i]);
      }
    }
  }
}

void appendNodes(parent, nodes) {
  for (var i = 0; i < nodes.length; i++) {
    DOM.appendChild(parent, nodes[i]);
  }
}

Function decoratePreventDefault(Function eventHandler) {
  return (event) {
    var allowDefaultBehavior = eventHandler(event);
    if (identical(allowDefaultBehavior, false)) {
      // TODO(tbosch): move preventDefault into event plugins...
      DOM.preventDefault(event);
    }
  };
}

var NS_PREFIX_RE = new RegExp(r'^@([^:]+):(.+)');
List<String> splitNamespace(String name) {
  if (name[0] != '@') {
    return [null, name];
  }
  var match = NS_PREFIX_RE.firstMatch(name);
  return [match[1], match[2]];
}
