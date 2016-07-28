import 'package:angular2/platform/common_dom.dart';
import 'package:angular2/src/compiler/xhr.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;

const _attrToPropMap = const {
  'innerHtml': 'innerHTML',
  'readonly': 'readOnly',
  'tabindex': 'tabIndex',
};

abstract class AbstractHtml5LibAdapter
    implements DomAdapter<Element, Node, Node> {
  hasProperty(element, String name) {
    // This is needed for serverside compile to generate the right getters/setters.
    // TODO: change this once we have property schema support.
    // Attention: Keep this in sync with browser_adapter.dart!
    return true;
  }

  void setProperty(Element element, String name, Object value);

  getProperty(Element element, String name);

  @override
  get attrToPropMap => _attrToPropMap;

  @override
  set attrToPropMap(value) {
    throw 'readonly';
  }

  @override
  getGlobalEventTarget(String target);

  @override
  getTitle();

  @override
  setTitle(String newTitle);

  @override
  String getEventKey(event);

  @override
  void replaceChild(el, newNode, oldNode);

  @override
  dynamic getBoundingClientRect(el);

  @override
  Type getXHR() => XHR;

  Element parse(String templateHtml) => parser.parse(templateHtml).firstChild;
  query(selector);

  querySelector(el, String selector) {
    return el.querySelector(selector);
  }

  List querySelectorAll(el, String selector) {
    return el.querySelectorAll(selector);
  }

  on(el, evt, listener);

  Function onAndCancel(el, evt, listener);

  dispatchEvent(el, evt);

  createMouseEvent(eventType);

  createEvent(eventType);

  preventDefault(evt);

  isPrevented(evt);

  getInnerHTML(el) {
    return el.innerHtml;
  }

  getTemplateContent(el);

  getOuterHTML(el) {
    return el.outerHtml;
  }

  String nodeName(node) {
    switch (node.nodeType) {
      case Node.ELEMENT_NODE:
        return (node as Element).localName;
      case Node.TEXT_NODE:
        return '#text';
      default:
        throw 'not implemented for type ${node.nodeType}. '
            'See http://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-1950641247'
            ' for node types definitions.';
    }
  }

  String nodeValue(Node node) {
    if (node is Text) return node.data;
    if (node is Comment) return node.data;
    return null;
  }

  String type(node) {
    throw new UnimplementedError();
  }

  content(node) {
    return node;
  }

  firstChild(Element el) =>
      el is NodeList ? (el as NodeList).first : el.firstChild;

  nextSibling(el) {
    final parentNode = el.parentNode;
    if (parentNode == null) return null;
    final siblings = parentNode.nodes;
    final index = siblings.indexOf(el);
    if (index < siblings.length - 1) {
      return siblings[index + 1];
    }
    return null;
  }

  parentElement(el) {
    return el.parent;
  }

  List childNodes(el) => el.nodes;
  List childNodesAsList(el) => el.nodes;
  clearNodes(el) {
    el.nodes.forEach((e) => e.remove());
  }

  appendChild(el, node) => el.append(node.remove());
  removeChild(el, node);

  remove(el) => el.remove();
  insertBefore(el, node) {
    if (el.parent == null) throw '$el must have a parent';
    el.parent.insertBefore(node, el);
  }

  insertAllBefore(el, nodes);

  insertAfter(el, node);

  setInnerHTML(el, value) {
    el.innerHtml = value;
  }

  getText(el) {
    return el.text;
  }

  setText(el, String value) => el.text = value;

  getValue(el);

  setValue(el, String value);

  getChecked(el);

  setChecked(el, bool value);

  createComment(String text) => new Comment(text);
  createTemplate(String html) => createElement('template')..innerHtml = html;
  createElement(tagName, [doc]) {
    return new Element.tag(tagName);
  }

  createElementNS(ns, tagName, [doc]);

  createTextNode(String text, [doc]) => new Text(text);

  createScriptTag(String attrName, String attrValue, [doc]);

  createStyleElement(String css, [doc]);

  createShadowRoot(el);

  getShadowRoot(el);

  getHost(el);

  clone(node) => node.clone(true);
  getElementsByClassName(element, String name);

  getElementsByTagName(element, String name);

  List<String> classList(Element element) => element.classes.toList();

  addClass(element, String className) {
    element.classes.add(className);
  }

  removeClass(element, String className);

  hasClass(element, String className) => element.classes.contains(className);

  setStyle(element, String styleName, String styleValue);

  bool hasStyle(Element element, String styleName, [String styleValue]);

  removeStyle(element, String styleName);

  getStyle(element, String styleName);

  String tagName(element) => element.localName;

  attributeMap(element) {
    // `attributes` keys can be {@link AttributeName}s.
    var map = <String, String>{};
    element.attributes.forEach((key, value) {
      map['$key'] = value;
    });
    return map;
  }

  hasAttribute(element, String attribute) {
    // `attributes` keys can be {@link AttributeName}s.
    return element.attributes.keys.any((key) => '$key' == attribute);
  }

  hasAttributeNS(element, String ns, String attribute);

  getAttribute(element, String attribute) {
    // `attributes` keys can be {@link AttributeName}s.
    var key = element.attributes.keys
        .firstWhere((key) => '$key' == attribute, orElse: () {});
    return element.attributes[key];
  }

  getAttributeNS(element, String ns, String attribute);

  setAttribute(element, String name, String value) {
    element.attributes[name] = value;
  }

  setAttributeNS(element, String ns, String name, String value);

  removeAttribute(element, String attribute) {
    element.attributes.remove(attribute);
  }

  removeAttributeNS(element, String ns, String attribute);

  templateAwareRoot(el) => el;

  createHtmlDocument();

  defaultDoc();

  bool elementMatches(n, String selector);

  bool isTemplateElement(Element el) {
    return el != null && el.localName.toLowerCase() == 'template';
  }

  bool isTextNode(node) => node.nodeType == Node.TEXT_NODE;
  bool isCommentNode(node) => node.nodeType == Node.COMMENT_NODE;

  bool isElementNode(node) => node.nodeType == Node.ELEMENT_NODE;

  bool hasShadowRoot(node);

  bool isShadowRoot(node);

  importIntoDoc(node);

  adoptNode(node);

  String getHref(element);

  void resolveAndSetHref(element, baseUrl, href);

  List getDistributedNodes(Node);

  bool supportsDOMEvents() {
    return false;
  }

  bool supportsNativeShadowDOM() {
    return false;
  }

  getHistory();

  getLocation();

  getBaseHref();

  resetBaseElement();

  String getUserAgent() {
    return 'Angular 2 Dart Transformer';
  }

  void setData(Element element, String name, String value) {
    this.setAttribute(element, 'data-${name}', value);
  }

  getComputedStyle(element);

  String getData(Element element, String name) {
    return this.getAttribute(element, 'data-${name}');
  }

  // TODO(tbosch): move this into a separate environment class once we have it
  setGlobalVar(String name, value) {
    // noop on the server
  }

  requestAnimationFrame(callback);

  cancelAnimationFrame(id);

  performanceNow();

  getAnimationPrefix();

  getTransitionEnd();

  supportsAnimation();
}
