import 'dart:io';

import 'package:angular2/platform/common_dom.dart';
import 'package:html/dom.dart';

import 'abstract_html_adapter.dart';

class Html5LibDomAdapter extends AbstractHtml5LibAdapter {
  static void makeCurrent() {
    setRootDomAdapter(new Html5LibDomAdapter());
  }

  void logError(errorMessage) {
    stderr.writeln('${errorMessage}');
  }

  void log(message) {
    stdout.writeln('${message}');
  }

  void logGroup(message) {
    stdout.writeln('${message}');
  }

  void logGroupEnd() {}

  @override
  void setProperty(Element element, String name, Object value) {
    throw new UnimplementedError();
  }

  @override
  dynamic getProperty(Element element, String name) {
    throw new UnimplementedError();
  }

  @override
  dynamic getTemplateContent(Element el) {
    throw new UnimplementedError();
  }

  @override
  String getTitle() {
    throw new UnimplementedError();
  }

  @override
  void setTitle(String newTitle) {
    throw new UnimplementedError();
  }

  @override
  String getEventKey(event) {
    throw new UnimplementedError();
  }

  @override
  void replaceChild(el, newNode, oldNode) {
    throw new UnimplementedError();
  }

  @override
  dynamic getBoundingClientRect(el) {
    throw new UnimplementedError();
  }

  @override
  dynamic query(selector) {
    throw new UnimplementedError();
  }

  @override
  void on(el, evt, listener) {
    throw new UnimplementedError();
  }

  @override
  Function onAndCancel(el, evt, listener) {
    throw new UnimplementedError();
  }

  @override
  void dispatchEvent(el, evt) {
    throw new UnimplementedError();
  }

  @override
  dynamic createMouseEvent(eventType) {
    throw new UnimplementedError();
  }

  @override
  dynamic createEvent(eventType) {
    throw new UnimplementedError();
  }

  @override
  void preventDefault(evt) {
    throw new UnimplementedError();
  }

  @override
  bool isPrevented(evt) {
    throw new UnimplementedError();
  }

  @override
  void removeChild(el, node) {
    throw new UnimplementedError();
  }

  @override
  void insertAllBefore(el, nodes) {
    throw new UnimplementedError();
  }

  @override
  void insertAfter(el, node) {
    throw new UnimplementedError();
  }

  @override
  String getValue(el) {
    throw new UnimplementedError();
  }

  @override
  void setValue(el, String value) {
    throw new UnimplementedError();
  }

  @override
  bool getChecked(el) {
    throw new UnimplementedError();
  }

  @override
  void setChecked(el, bool value) {
    throw new UnimplementedError();
  }

  @override
  Element createElementNS(ns, tagName, [doc]) {
    throw new UnimplementedError();
  }

  @override
  dynamic createScriptTag(String attrName, String attrValue, [doc]) {
    throw new UnimplementedError();
  }

  @override
  dynamic createStyleElement(String css, [doc]) {
    throw new UnimplementedError();
  }

  @override
  dynamic createShadowRoot(el) {
    throw new UnimplementedError();
  }

  @override
  dynamic getShadowRoot(el) {
    throw new UnimplementedError();
  }

  @override
  dynamic getHost(el) {
    throw new UnimplementedError();
  }

  @override
  List<Node> getElementsByClassName(element, String name) {
    throw new UnimplementedError();
  }

  @override
  List<Node> getElementsByTagName(element, String name) {
    throw new UnimplementedError();
  }

  @override
  void removeClass(element, String className) {
    throw new UnimplementedError();
  }

  @override
  void setStyle(element, String styleName, String styleValue) {
    throw new UnimplementedError();
  }

  @override
  bool hasStyle(Element element, String styleName, [String styleValue]) {
    throw new UnimplementedError();
  }

  @override
  void removeStyle(element, String styleName) {
    throw new UnimplementedError();
  }

  @override
  String getStyle(element, String styleName) {
    throw new UnimplementedError();
  }

  @override
  bool hasAttributeNS(element, String ns, String attribute) {
    throw new UnimplementedError();
  }

  @override
  String getAttributeNS(element, String ns, String attribute) {
    throw new UnimplementedError();
  }

  @override
  void setAttributeNS(element, String ns, String name, String value) {
    throw new UnimplementedError();
  }

  @override
  void removeAttributeNS(element, String ns, String attribute) {
    throw new UnimplementedError();
  }

  @override
  dynamic createHtmlDocument() {
    throw new UnimplementedError();
  }

  @override
  dynamic defaultDoc() {
    throw new UnimplementedError();
  }

  @override
  bool elementMatches(n, String selector) {
    throw new UnimplementedError();
  }

  @override
  bool hasShadowRoot(node) {
    throw new UnimplementedError();
  }

  @override
  bool isShadowRoot(node) {
    throw new UnimplementedError();
  }

  @override
  dynamic importIntoDoc(node) {
    throw new UnimplementedError();
  }

  @override
  dynamic adoptNode(node) {
    throw new UnimplementedError();
  }

  @override
  String getHref(element) {
    throw new UnimplementedError();
  }

  @override
  void resolveAndSetHref(element, baseUrl, href) {
    throw new UnimplementedError();
  }

  @override
  List getDistributedNodes(Node) {
    throw new UnimplementedError();
  }

  @override
  dynamic getHistory() {
    throw new UnimplementedError();
  }

  @override
  dynamic getLocation() {
    throw new UnimplementedError();
  }

  @override
  String getBaseHref() {
    throw new UnimplementedError();
  }

  @override
  void resetBaseElement() {
    throw new UnimplementedError();
  }

  @override
  dynamic getComputedStyle(element) {
    throw new UnimplementedError();
  }

  @override
  num requestAnimationFrame(callback) {
    throw new UnimplementedError();
  }

  @override
  void cancelAnimationFrame(id) {
    throw new UnimplementedError();
  }

  @override
  num performanceNow() {
    throw new UnimplementedError();
  }

  @override
  String getAnimationPrefix() {
    throw new UnimplementedError();
  }

  @override
  String getTransitionEnd() {
    throw new UnimplementedError();
  }

  @override
  bool supportsAnimation() {
    throw new UnimplementedError();
  }
}
