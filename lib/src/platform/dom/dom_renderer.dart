import 'package:angular2/src/animate/animation_builder.dart'
    show AnimationBuilder;
import 'package:angular2/src/core/di.dart' show Inject, Injectable;
import 'package:angular2/src/core/metadata.dart' show ViewEncapsulation;
import 'package:angular2/src/core/render/api.dart'
    show Renderer, RootRenderer, RenderComponentType, RenderDebugInfo;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;
import 'package:angular2/src/facade/lang.dart' show Json;
import 'package:angular2/src/platform/dom/dom_adapter.dart' show DOM;

import 'dom_tokens.dart' show DOCUMENT;
import 'events/event_manager.dart' show EventManager;
import 'shared_styles_host.dart' show DomSharedStylesHost;
import 'util.dart' show camelCaseToDashCase;

const NAMESPACE_URIS = const {
  'xlink': 'http://www.w3.org/1999/xlink',
  'svg': 'http://www.w3.org/2000/svg'
};
const TEMPLATE_COMMENT_TEXT = 'template bindings={}';
var TEMPLATE_BINDINGS_EXP = new RegExp(r'^template bindings=(.*)$');

@Injectable()
class DomRootRenderer implements RootRenderer {
  static bool isDirty = false;
  dynamic document;
  EventManager eventManager;
  DomSharedStylesHost sharedStylesHost;
  AnimationBuilder animate;
  var _registeredComponents = <String, DomRenderer>{};

  DomRootRenderer(@Inject(DOCUMENT) this.document, this.eventManager,
      this.sharedStylesHost, this.animate);

  Renderer renderComponent(RenderComponentType componentProto) {
    var renderer = this._registeredComponents[componentProto.id];
    if (renderer == null) {
      renderer = new DomRenderer(this, componentProto);
      this._registeredComponents[componentProto.id] = renderer;
    }
    return renderer;
  }
}

class DomRenderer implements Renderer {
  DomRootRenderer _rootRenderer;
  RenderComponentType componentProto;
  String _contentAttr;
  String _hostAttr;
  List<String> _styles;

  DomRenderer(@Inject(RootRenderer) this._rootRenderer, this.componentProto) {
    this._styles = _flattenStyles(componentProto.id, componentProto.styles, []);
    if (!identical(componentProto.encapsulation, ViewEncapsulation.Native)) {
      this._rootRenderer.sharedStylesHost.addStyles(this._styles);
    }
    if (identical(
        this.componentProto.encapsulation, ViewEncapsulation.Emulated)) {
      this._contentAttr = _shimContentAttribute(componentProto.id);
      this._hostAttr = _shimHostAttribute(componentProto.id);
    } else {
      this._contentAttr = null;
      this._hostAttr = null;
    }
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
    if (_contentAttr != null) {
      DOM.setAttribute(el, this._contentAttr, '');
    }
    if (parent != null) {
      DOM.appendChild(parent, el);
    }
    DomRootRenderer.isDirty = true;
    return el;
  }

  dynamic createViewRoot(dynamic hostElement) {
    var nodesParent;
    if (identical(
        this.componentProto.encapsulation, ViewEncapsulation.Native)) {
      nodesParent = DOM.createShadowRoot(hostElement);
      this._rootRenderer.sharedStylesHost.addHost(nodesParent);
      for (var i = 0; i < this._styles.length; i++) {
        DOM.appendChild(nodesParent, DOM.createStyleElement(this._styles[i]));
      }
    } else {
      if (_hostAttr != null) {
        DOM.setAttribute(hostElement, this._hostAttr, '');
      }
      nodesParent = hostElement;
    }
    DomRootRenderer.isDirty = true;
    return nodesParent;
  }

  dynamic createTemplateAnchor(
      dynamic parentElement, RenderDebugInfo debugInfo) {
    var comment = DOM.createComment(TEMPLATE_COMMENT_TEXT);
    if (parentElement != null) {
      DOM.appendChild(parentElement, comment);
    }
    return comment;
  }

  dynamic createText(
      dynamic parentElement, String value, RenderDebugInfo debugInfo) {
    var node = DOM.createTextNode(value);
    if (parentElement != null) {
      DOM.appendChild(parentElement, node);
    }
    DomRootRenderer.isDirty = true;
    return node;
  }

  projectNodes(dynamic parentElement, List<dynamic> nodes) {
    if (parentElement == null) return;
    appendNodes(parentElement, nodes);
    DomRootRenderer.isDirty = true;
  }

  attachViewAfter(dynamic node, List<dynamic> viewRootNodes) {
    moveNodesAfterSibling(node, viewRootNodes);
    int len = viewRootNodes.length;
    for (var i = 0; i < len; i++) {
      this.animateNodeEnter(viewRootNodes[i]);
    }
    DomRootRenderer.isDirty = true;
  }

  detachView(List<dynamic> viewRootNodes) {
    int len = viewRootNodes.length;
    for (var i = 0; i < len; i++) {
      var node = viewRootNodes[i];
      DOM.remove(node);
      this.animateNodeLeave(node);
      DomRootRenderer.isDirty = true;
    }
  }

  destroyView(dynamic hostElement, List<dynamic> viewAllNodes) {
    if (componentProto.encapsulation == ViewEncapsulation.Native &&
        hostElement != null) {
      _rootRenderer.sharedStylesHost.removeHost(DOM.getShadowRoot(hostElement));
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

  void setElementAttribute(
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

  void setBindingDebugInfo(
      dynamic renderElement, String propertyName, String propertyValue) {
    var dashCasedPropertyName = camelCaseToDashCase(propertyName);
    if (DOM.isCommentNode(renderElement)) {
      var existingBindings = TEMPLATE_BINDINGS_EXP.firstMatch(
          DOM.getText(renderElement).replaceAll(new RegExp(r'\n'), ''));
      var parsedBindings = Json.parse(existingBindings[1]);
      parsedBindings[dashCasedPropertyName] = propertyValue;
      DOM.setText(
          renderElement,
          TEMPLATE_COMMENT_TEXT.replaceFirst(
              '{}', Json.stringify(parsedBindings)));
    } else {
      this.setElementAttribute(renderElement, propertyName, propertyValue);
    }
  }

  void setElementClass(dynamic renderElement, String className, bool isAdd) {
    if (isAdd) {
      DOM.addClass(renderElement, className);
    } else {
      DOM.removeClass(renderElement, className);
    }
    DomRootRenderer.isDirty = true;
  }

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

  /// Performs animations if necessary.
  animateNodeEnter(dynamic node) {
    if (DOM.isElementNode(node) && DOM.hasClass(node, 'ng-animate')) {
      DOM.addClass(node, 'ng-enter');
      DomRootRenderer.isDirty = true;
      this
          ._rootRenderer
          .animate
          .css()
          .addAnimationClass('ng-enter-active')
          .start((node as dynamic))
          .onComplete(() {
        DOM.removeClass(node, 'ng-enter');
        DomRootRenderer.isDirty = true;
      });
    }
  }

  /// If animations are necessary, performs animations then removes the element;
  /// otherwise, it just removes the element.
  animateNodeLeave(dynamic node) {
    if (DOM.isElementNode(node) && DOM.hasClass(node, 'ng-animate')) {
      DOM.addClass(node, 'ng-leave');
      DomRootRenderer.isDirty = true;
      this
          ._rootRenderer
          .animate
          .css()
          .addAnimationClass('ng-leave-active')
          .start((node as dynamic))
          .onComplete(() {
        DOM.removeClass(node, 'ng-leave');
        DOM.remove(node);
        DomRootRenderer.isDirty = true;
      });
    } else {
      DOM.remove(node);
      DomRootRenderer.isDirty = true;
    }
  }
}

moveNodesAfterSibling(sibling, nodes) {
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

appendNodes(parent, nodes) {
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

var COMPONENT_REGEX = new RegExp(r'%COMP%');
const COMPONENT_VARIABLE = '%COMP%';
final HOST_ATTR = '_nghost-${ COMPONENT_VARIABLE}';
final CONTENT_ATTR = '_ngcontent-${ COMPONENT_VARIABLE}';
String _shimContentAttribute(String componentShortId) {
  return CONTENT_ATTR.replaceAll(COMPONENT_REGEX, componentShortId);
}

String _shimHostAttribute(String componentShortId) {
  return HOST_ATTR.replaceAll(COMPONENT_REGEX, componentShortId);
}

List<String> _flattenStyles(
    String compId,
    List<dynamic /* dynamic | List < dynamic > */ > styles,
    List<String> target) {
  for (var i = 0; i < styles.length; i++) {
    var style = styles[i];
    if (style is List) {
      _flattenStyles(compId, style, target);
    } else {
      style = style.replaceAll(COMPONENT_REGEX, compId);
      target.add(style);
    }
  }
  return target;
}

var NS_PREFIX_RE = new RegExp(r'^@([^:]+):(.+)');
List<String> splitNamespace(String name) {
  if (name[0] != '@') {
    return [null, name];
  }
  var match = NS_PREFIX_RE.firstMatch(name);
  return [match[1], match[2]];
}
