import "package:angular2/di.dart" show Injectable;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;

typedef void LogFunction([a, b, c, d, e]);

@Injectable()
class Log {
  final List logItems = new List();

  void add(value) {
    this.logItems.add(value);
  }

  LogFunction fn(value) {
    return (
        [dynamic a1 = null,
        dynamic a2 = null,
        dynamic a3 = null,
        dynamic a4 = null,
        dynamic a5 = null]) {
      this.logItems.add(value);
    };
  }

  void clear() {
    this.logItems.clear();
  }

  String result() => this.logItems.join("; ");
}

BrowserDetection browserDetection;

class BrowserDetection {
  String _ua;
  static void setup() {
    browserDetection = new BrowserDetection(null);
  }

  BrowserDetection(String ua) {
    _ua = ua ?? (DOM != null ? DOM.getUserAgent() : '');
  }
  bool get isFirefox => _ua.indexOf("Firefox") > -1;

  bool get isAndroid =>
      _ua.indexOf("Mozilla/5.0") > -1 &&
      _ua.indexOf("Android") > -1 &&
      _ua.indexOf("AppleWebKit") > -1 &&
      _ua.indexOf("Chrome") == -1;

  bool get isEdge => _ua.indexOf("Edge") > -1;

  bool get isIE => _ua.indexOf("Trident") > -1;

  bool get isWebkit =>
      _ua.indexOf("AppleWebKit") > -1 && _ua.indexOf("Edge") == -1;

  bool get isIOS7 =>
      _ua.indexOf("iPhone OS 7") > -1 || _ua.indexOf("iPad OS 7") > -1;

  bool get isSlow => isAndroid || isIE || isIOS7;

  // The Intl API is only properly supported in recent Chrome and Opera.

  // Note: Edge is disguised as Chrome 42, so checking the "Edge" part is needed,

  // see https://msdn.microsoft.com/en-us/library/hh869301(v=vs.85).aspx
  bool get supportsIntlApi =>
      _ua.indexOf("Chrome/4") > -1 && _ua.indexOf("Edge") == -1;
}

void dispatchEvent(element, eventType) {
  DOM.dispatchEvent(element, DOM.createEvent(eventType));
}

dynamic el(String html) {
  return (DOM.firstChild(DOM.content(DOM.createTemplate(html))) as dynamic);
}

var _RE_SPECIAL_CHARS = [
  "-",
  "[",
  "]",
  "/",
  "{",
  "}",
  "\\",
  "(",
  ")",
  "*",
  "+",
  "?",
  ".",
  "^",
  "\$",
  "|"
];
final _ESCAPE_RE = new RegExp('''[\\${ _RE_SPECIAL_CHARS . join ( "\\" )}]''');
RegExp containsRegexp(String input) {
  return new RegExp(
      input.replaceAllMapped(_ESCAPE_RE, (match) => '''\\${ match [ 0 ]}'''));
}

RegExp _normalizerExp1,
    _normalizerExp2,
    _normalizerExp3,
    _normalizerExp4,
    _normalizerExp5,
    _normalizerExp6;

String normalizeCSS(String css) {
  _normalizerExp1 ??= new RegExp(r'\s+');
  _normalizerExp2 ??= new RegExp(r':\s');
  _normalizerExp3 ??= new RegExp('' + "'" + r'');
  _normalizerExp4 ??= new RegExp(' }');
  _normalizerExp5 ??= new RegExp(r'url\((\"|\s)(.+)(\"|\s)\)(\s*)');
  _normalizerExp6 ??= new RegExp(r'\[(.+)=([^"\]]+)\]');
  css = css.replaceAll(_normalizerExp1, " ");
  css = css.replaceAll(_normalizerExp2, ":");
  css = css.replaceAll(_normalizerExp3, "\"");
  css = css.replaceAll(_normalizerExp4, "}");
  css = css.replaceAllMapped(
      _normalizerExp5, (match) => '''url("${ match [ 2 ]}")''');
  css = css.replaceAllMapped(
      _normalizerExp6, (match) => '''[${ match [ 1 ]}="${ match [ 2 ]}"]''');
  return css;
}

var _singleTagWhitelist = const ['br', 'hr', 'input'];
String stringifyElement(el) {
  var result = "";
  if (DOM.isElementNode(el)) {
    var tagName = DOM.tagName(el).toLowerCase();
    // Opening tag
    result += '''<${ tagName}''';
    // Attributes in an ordered way
    var attributeMap = DOM.attributeMap(el);
    var keys = [];
    attributeMap.forEach((k, v) => keys.add(k));
    keys.sort();
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      var attValue = attributeMap[key];
      if (attValue is! String) {
        result += ''' ${ key}''';
      } else {
        result += ''' ${ key}="${ attValue}"''';
      }
    }
    result += ">";
    // Children
    var childrenRoot = DOM.templateAwareRoot(el);
    var children = childrenRoot != null ? DOM.childNodes(childrenRoot) : [];
    for (var j = 0; j < children.length; j++) {
      result += stringifyElement(children[j]);
    }
    // Closing tag
    if (!_singleTagWhitelist.contains(tagName)) {
      result += '''</${ tagName}>''';
    }
  } else if (DOM.isCommentNode(el)) {
    result += '''<!--${ DOM . nodeValue ( el )}-->''';
  } else {
    result += DOM.getText(el);
  }
  return result;
}
