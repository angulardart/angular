/// Singleton adapter used by renderer layer.
DomAdapter DOM;
void setRootDomAdapter(DomAdapter adapter) {
  DOM ??= adapter;
}

/// Provides DOM operations in an environment-agnostic way.
abstract class DomAdapter<T, N, ET> {
  bool hasProperty(T element, String name);
  void setProperty(T element, String name, dynamic value);
  dynamic getProperty(T element, String name);
  void logError(error);
  void log(error);
  void logGroup(error);
  void logGroupEnd();

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
  void parse(String templateHtml);
  dynamic query(String selector);
  dynamic querySelector(el, String selector);
  List<dynamic> querySelectorAll(el, String selector);
  void on(ET eventTarget, String evt, listener(arg));
  Function onAndCancel(T el, String evt, listener(arg));
  void dispatchEvent(T el, evt);
  dynamic createMouseEvent(String eventType);
  dynamic createEvent(String eventType);
  void preventDefault(evt);
  bool isPrevented(evt);
  String getInnerHTML(T el);
  dynamic getTemplateContent(T el);
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
  void clearNodes(T el);
  void appendChild(T el, N node);
  void removeChild(T el, N node);
  void replaceChild(T el, N newNode, N oldNode);
  dynamic remove(T el);
  void insertBefore(T el, N node);
  void insertAllBefore(T el, List<N> nodes);
  void insertAfter(T el, N node);
  void setInnerHTML(T el, String value);
  String getText(T el);
  void setText(T el, String value);
  String getValue(T el);
  void setValue(T el, String value);
  bool getChecked(T el);
  void setChecked(T el, bool value);
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
  void addClass(T element, String className);
  void removeClass(T element, String className);
  bool hasClass(T element, String className);
  void setStyle(T element, String styleName, String styleValue);
  void removeStyle(T element, String styleName);
  String getStyle(T element, String styleName);
  bool hasStyle(T element, String styleName, [String styleValue]);
  String tagName(T element);
  Map<String, String> attributeMap(T element);
  bool hasAttribute(T element, String attribute);
  bool hasAttributeNS(T element, String ns, String attribute);
  String getAttribute(T element, String attribute);
  String getAttributeNS(T element, String ns, String attribute);
  void setAttribute(T element, String name, String value);
  void setAttributeNS(T element, String ns, String name, String value);
  void removeAttribute(T element, String attribute);
  void removeAttributeNS(T element, String ns, String attribute);
  dynamic templateAwareRoot(T el);
  dynamic createHtmlDocument();
  dynamic defaultDoc();
  void getBoundingClientRect(T el);
  String getTitle();
  void setTitle(String newTitle);
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
  void resolveAndSetHref(T element, String baseUrl, String href);
  bool supportsDOMEvents();
  bool supportsNativeShadowDOM();
  dynamic getHistory();
  dynamic getLocation();
  String getBaseHref();
  void resetBaseElement();
  String getUserAgent();
  void setData(T element, String name, String value);
  dynamic getComputedStyle(T element);
  String getData(T element, String name);
  void setGlobalVar(String name, dynamic value);
  num requestAnimationFrame(callback);
  void cancelAnimationFrame(id);
  num performanceNow();
  String getAnimationPrefix();
  String getTransitionEnd();
  bool supportsAnimation();
}
