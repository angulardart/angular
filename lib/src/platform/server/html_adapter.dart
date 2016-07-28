import 'dart:io';

import 'package:angular2/platform/common_dom.dart';
import 'package:html/dom.dart';

import 'abstract_html_adapter.dart';

class Html5LibDomAdapter extends AbstractHtml5LibAdapter {
  static void makeCurrent() {
    setRootDomAdapter(new Html5LibDomAdapter());
  }

  logError(errorMessage) {
    stderr.writeln('${errorMessage}');
  }

  log(message) {
    stdout.writeln('${message}');
  }

  logGroup(message) {
    stdout.writeln('${message}');
  }

  logGroupEnd() {}

  @override
  void setProperty(Element element, String name, Object value) {
    throw new UnimplementedError();
  }

  @override
  getProperty(Element element, String name) {
    throw new UnimplementedError();
  }

  @override
  getTemplateContent(Element el) {
    throw new UnimplementedError();
  }

  @override
  getGlobalEventTarget(String target) {
    throw new UnimplementedError();
  }

  @override
  getTitle() {
    throw new UnimplementedError();
  }

  @override
  setTitle(String newTitle) {
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
  query(selector) {
    throw new UnimplementedError();
  }

  @override
  on(el, evt, listener) {
    throw new UnimplementedError();
  }

  @override
  Function onAndCancel(el, evt, listener) {
    throw new UnimplementedError();
  }

  @override
  dispatchEvent(el, evt) {
    throw new UnimplementedError();
  }

  @override
  createMouseEvent(eventType) {
    throw new UnimplementedError();
  }

  @override
  createEvent(eventType) {
    throw new UnimplementedError();
  }

  @override
  preventDefault(evt) {
    throw new UnimplementedError();
  }

  @override
  isPrevented(evt) {
    throw new UnimplementedError();
  }

  @override
  removeChild(el, node) {
    throw new UnimplementedError();
  }

  @override
  insertAllBefore(el, nodes) {
    throw new UnimplementedError();
  }

  @override
  insertAfter(el, node) {
    throw new UnimplementedError();
  }

  @override
  getValue(el) {
    throw new UnimplementedError();
  }

  @override
  setValue(el, String value) {
    throw new UnimplementedError();
  }

  @override
  getChecked(el) {
    throw new UnimplementedError();
  }

  @override
  setChecked(el, bool value) {
    throw new UnimplementedError();
  }

  @override
  createElementNS(ns, tagName, [doc]) {
    throw new UnimplementedError();
  }

  @override
  createScriptTag(String attrName, String attrValue, [doc]) {
    throw new UnimplementedError();
  }

  @override
  createStyleElement(String css, [doc]) {
    throw new UnimplementedError();
  }

  @override
  createShadowRoot(el) {
    throw new UnimplementedError();
  }

  @override
  getShadowRoot(el) {
    throw new UnimplementedError();
  }

  @override
  getHost(el) {
    throw new UnimplementedError();
  }

  @override
  getElementsByClassName(element, String name) {
    throw new UnimplementedError();
  }

  @override
  getElementsByTagName(element, String name) {
    throw new UnimplementedError();
  }

  @override
  removeClass(element, String className) {
    throw new UnimplementedError();
  }

  @override
  setStyle(element, String styleName, String styleValue) {
    throw new UnimplementedError();
  }

  @override
  bool hasStyle(Element element, String styleName, [String styleValue]) {
    throw new UnimplementedError();
  }

  @override
  removeStyle(element, String styleName) {
    throw new UnimplementedError();
  }

  @override
  getStyle(element, String styleName) {
    throw new UnimplementedError();
  }

  @override
  hasAttributeNS(element, String ns, String attribute) {
    throw new UnimplementedError();
  }

  @override
  getAttributeNS(element, String ns, String attribute) {
    throw new UnimplementedError();
  }

  @override
  setAttributeNS(element, String ns, String name, String value) {
    throw new UnimplementedError();
  }

  @override
  removeAttributeNS(element, String ns, String attribute) {
    throw new UnimplementedError();
  }

  @override
  createHtmlDocument() {
    throw new UnimplementedError();
  }

  @override
  defaultDoc() {
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
  importIntoDoc(node) {
    throw new UnimplementedError();
  }

  @override
  adoptNode(node) {
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
  getHistory() {
    throw new UnimplementedError();
  }

  @override
  getLocation() {
    throw new UnimplementedError();
  }

  @override
  getBaseHref() {
    throw new UnimplementedError();
  }

  @override
  resetBaseElement() {
    throw new UnimplementedError();
  }

  @override
  getComputedStyle(element) {
    throw new UnimplementedError();
  }

  @override
  requestAnimationFrame(callback) {
    throw new UnimplementedError();
  }

  @override
  cancelAnimationFrame(id) {
    throw new UnimplementedError();
  }

  @override
  performanceNow() {
    throw new UnimplementedError();
  }

  @override
  getAnimationPrefix() {
    throw new UnimplementedError();
  }

  @override
  getTransitionEnd() {
    throw new UnimplementedError();
  }

  @override
  supportsAnimation() {
    throw new UnimplementedError();
  }
}
