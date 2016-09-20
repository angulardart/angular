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
  bool hasProperty(element, String name) {
    // This is needed for serverside compile to generate the right getters/setters.
    // TODO: change this once we have property schema support.
    // Attention: Keep this in sync with browser_adapter.dart!
    return true;
  }

  void setProperty(Element element, String name, Object value);

  @override
  Map<String, String> get attrToPropMap => _attrToPropMap;

  @override
  set attrToPropMap(value) {
    throw 'readonly';
  }

  @override
  String getTitle();

  @override
  void setTitle(String newTitle);

  @override
  String getEventKey(event);

  @override
  void replaceChild(el, newNode, oldNode);

  @override
  dynamic getBoundingClientRect(el);

  @override
  Type getXHR() => XHR;

  Element parse(String templateHtml) => parser.parse(templateHtml).firstChild;

  dynamic querySelector(el, String selector) {
    return el.querySelector(selector);
  }

  List querySelectorAll(el, String selector) {
    return el.querySelectorAll(selector);
  }

  void on(el, evt, listener);

  Function onAndCancel(el, evt, listener);

  String getInnerHTML(el) {
    return el.innerHtml;
  }

  String getOuterHTML(el) {
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

  dynamic content(node) {
    return node;
  }

  dynamic firstChild(Element el) =>
      el is NodeList ? (el as NodeList).first : el.firstChild;

  dynamic nextSibling(el) {
    final parentNode = el.parentNode;
    if (parentNode == null) return null;
    final siblings = parentNode.nodes;
    final index = siblings.indexOf(el);
    if (index < siblings.length - 1) {
      return siblings[index + 1];
    }
    return null;
  }

  dynamic parentElement(el) {
    return el.parent;
  }

  List childNodes(el) => el.nodes;
  List childNodesAsList(el) => el.nodes;
  void clearNodes(el) {
    el.nodes.forEach((e) => e.remove());
  }

  void appendChild(el, node) => el.append(node.remove());

  void remove(el) {
    el.remove();
  }

  void insertBefore(el, node) {
    if (el.parent == null) throw '$el must have a parent';
    el.parent.insertBefore(node, el);
  }

  void setInnerHTML(el, value) {
    el.innerHtml = value;
  }

  String getText(el) {
    return el.text;
  }

  String setText(el, String value) => el.text = value;

  dynamic createComment(String text) => new Comment(text);
  dynamic createTemplate(String html) =>
      createElement('template')..innerHtml = html;

  Element createElement(tagName, [doc]) {
    return new Element.tag(tagName);
  }

  Element createElementNS(ns, tagName, [doc]);

  Node createTextNode(String text, [doc]) => new Text(text);

  Node clone(node) => node.clone(true);

  List<String> classList(Element element) => element.classes.toList();

  void addClass(element, String className) {
    element.classes.add(className);
  }

  bool hasClass(element, String className) =>
      element.classes.contains(className);

  void setStyle(element, String styleName, String styleValue);

  String tagName(element) => element.localName;

  Map<String, String> attributeMap(element) {
    // `attributes` keys can be {@link AttributeName}s.
    var map = <String, String>{};
    element.attributes.forEach((key, value) {
      map['$key'] = value;
    });
    return map;
  }

  bool hasAttribute(element, String attribute) {
    // `attributes` keys can be {@link AttributeName}s.
    return element.attributes.keys.any((key) => '$key' == attribute);
  }

  String getAttribute(element, String attribute) {
    // `attributes` keys can be {@link AttributeName}s.
    var key = element.attributes.keys
        .firstWhere((key) => '$key' == attribute, orElse: () {});
    return element.attributes[key];
  }

  void setAttribute(element, String name, String value) {
    element.attributes[name] = value;
  }

  void removeAttribute(element, String attribute) {
    element.attributes.remove(attribute);
  }

  void removeAttributeNS(element, String ns, String attribute);

  dynamic templateAwareRoot(el) => el;

  bool isTemplateElement(Element el) {
    return el != null && el.localName.toLowerCase() == 'template';
  }

  bool isTextNode(node) => node.nodeType == Node.TEXT_NODE;
  bool isCommentNode(node) => node.nodeType == Node.COMMENT_NODE;

  bool isElementNode(node) => node.nodeType == Node.ELEMENT_NODE;

  dynamic importIntoDoc(node);

  bool supportsDOMEvents() {
    return false;
  }

  bool supportsNativeShadowDOM() {
    return false;
  }

  String getUserAgent() {
    return 'Angular 2 Dart Transformer';
  }

  void setData(Element element, String name, String value) {
    this.setAttribute(element, 'data-${name}', value);
  }

  String getData(Element element, String name) {
    return this.getAttribute(element, 'data-${name}');
  }

  // TODO(tbosch): move this into a separate environment class once we have it
  void setGlobalVar(String name, value) {
    // noop on the server
  }
}
