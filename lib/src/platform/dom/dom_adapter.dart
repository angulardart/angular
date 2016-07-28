/// Singleton adapter used by renderer layer.
DomAdapter DOM = null;
setRootDomAdapter(DomAdapter adapter) {
  DOM ??= adapter;
}

/// Provides DOM operations in an environment-agnostic way.
abstract class DomAdapter<T, N, ET> {
  bool hasProperty(T element, String name);
  setProperty(T element, String name, dynamic value);
  dynamic getProperty(T element, String name);
  logError(error);
  log(error);
  logGroup(error);
  logGroupEnd();

  Type getXHR();

  /// Maps attribute names to their corresponding property names for cases
  /// where attribute name doesn't match property name.
  Map<String, String> get attrToPropMap {
    return this._attrToPropMap;
  }

  set attrToPropMap(Map<String, String> value) {
    this._attrToPropMap = value;
  }

  Map<String, String> _attrToPropMap;
  parse(String templateHtml);
  dynamic query(String selector);
  dynamic querySelector(el, String selector);
  List<dynamic> querySelectorAll(el, String selector);
  on(ET eventTarget, String evt, listener(arg));
  Function onAndCancel(T el, String evt, listener(arg));
  dispatchEvent(T el, evt);
  dynamic createMouseEvent(String eventType);
  dynamic createEvent(String eventType);
  preventDefault(evt);
  bool isPrevented(evt);
  String getInnerHTML(T el);
  getTemplateContent(T el);
  String getOuterHTML(T el);
  String nodeName(N node);
  String nodeValue(N node);
  String type(inputElement);
  dynamic content(N node);
  dynamic firstChild(T el);
  dynamic nextSibling(T el);
  dynamic parentElement(T el);
  List<dynamic> childNodes(T el);
  List<dynamic> childNodesAsList(T el);
  clearNodes(T el);
  appendChild(T el, N node);
  removeChild(T el, N node);
  replaceChild(T el, N newNode, N oldNode);
  dynamic remove(T el);
  insertBefore(T el, N node);
  insertAllBefore(T el, List<N> nodes);
  insertAfter(T el, N node);
  setInnerHTML(T el, String value);
  String getText(T el);
  setText(T el, String value);
  String getValue(T el);
  setValue(T el, String value);
  bool getChecked(T el);
  setChecked(T el, bool value);
  dynamic createComment(String text);
  dynamic createTemplate(String html);
  T createElement(String tagName, [doc]);
  T createElementNS(String ns, String tagName, [doc]);
  N createTextNode(String text, [doc]);
  dynamic createScriptTag(String attrName, String attrValue, [doc]);
  dynamic createStyleElement(String css, [doc]);
  dynamic createShadowRoot(T el);
  dynamic getShadowRoot(T el);
  dynamic getHost(T el);
  List getDistributedNodes(T el);
  N clone(N node);
  List<N> getElementsByClassName(T element, String name);
  List<N> getElementsByTagName(T element, String name);
  List<String> classList(T element);
  addClass(T element, String className);
  removeClass(T element, String className);
  bool hasClass(T element, String className);
  setStyle(T element, String styleName, String styleValue);
  removeStyle(T element, String styleName);
  String getStyle(T element, String styleName);
  bool hasStyle(T element, String styleName, [String styleValue]);
  String tagName(T element);
  Map<String, String> attributeMap(T element);
  bool hasAttribute(T element, String attribute);
  bool hasAttributeNS(T element, String ns, String attribute);
  String getAttribute(T element, String attribute);
  String getAttributeNS(T element, String ns, String attribute);
  setAttribute(T element, String name, String value);
  setAttributeNS(T element, String ns, String name, String value);
  removeAttribute(T element, String attribute);
  removeAttributeNS(T element, String ns, String attribute);
  templateAwareRoot(T el);
  dynamic createHtmlDocument();
  dynamic defaultDoc();
  getBoundingClientRect(T el);
  String getTitle();
  setTitle(String newTitle);
  bool elementMatches(n, String selector);
  bool isTemplateElement(T el);
  bool isTextNode(N node);
  bool isCommentNode(N node);
  bool isElementNode(N node);
  bool hasShadowRoot(N node);
  bool isShadowRoot(N node);
  dynamic importIntoDoc(N node);
  dynamic adoptNode(N node);
  String getHref(T element);
  String getEventKey(event);
  resolveAndSetHref(T element, String baseUrl, String href);
  bool supportsDOMEvents();
  bool supportsNativeShadowDOM();
  dynamic getGlobalEventTarget(String target);
  dynamic getHistory();
  dynamic getLocation();
  String getBaseHref();
  void resetBaseElement();
  String getUserAgent();
  setData(T element, String name, String value);
  dynamic getComputedStyle(T element);
  String getData(T element, String name);
  setGlobalVar(String name, dynamic value);
  num requestAnimationFrame(callback);
  cancelAnimationFrame(id);
  num performanceNow();
  String getAnimationPrefix();
  String getTransitionEnd();
  bool supportsAnimation();
}
