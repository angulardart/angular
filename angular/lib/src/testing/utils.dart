import 'dart:html';

import 'package:angular/di.dart' show Injectable;

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

  String result() => this.logItems.join('; ');
}

BrowserDetection browserDetection;

class BrowserDetection {
  String _ua;
  static void setup() {
    browserDetection = new BrowserDetection(null);
  }

  BrowserDetection(String ua) {
    _ua = ua ?? (window.navigator.userAgent ?? '');
  }
  bool get isFirefox => _ua.indexOf('Firefox') > -1;

  bool get isAndroid =>
      _ua.indexOf('Mozilla/5.0') > -1 &&
      _ua.indexOf('Android') > -1 &&
      _ua.indexOf('AppleWebKit') > -1 &&
      _ua.indexOf('Chrome') == -1;

  bool get isEdge => _ua.indexOf('Edge') > -1;

  bool get isIE => _ua.indexOf('Trident') > -1;

  bool get isWebkit =>
      _ua.indexOf('AppleWebKit') > -1 && _ua.indexOf('Edge') == -1;

  bool get isIOS7 =>
      _ua.indexOf('iPhone OS 7') > -1 || _ua.indexOf('iPad OS 7') > -1;

  bool get isSlow => isAndroid || isIE || isIOS7;

  // The Intl API is only properly supported in recent Chrome and Opera.

  // Note: Edge is disguised as Chrome 42, so checking the 'Edge' part is needed,

  // see https://msdn.microsoft.com/en-us/library/hh869301(v=vs.85).aspx
  bool get supportsIntlApi =>
      _ua.indexOf('Chrome/4') > -1 && _ua.indexOf('Edge') == -1;
}

void dispatchEvent(Element element, String eventType) {
  element.dispatchEvent(new Event(eventType, canBubble: true));
}

var _RE_SPECIAL_CHARS = [
  '-',
  '[',
  ']',
  '/',
  '{',
  '}',
  '\\',
  '(',
  ')',
  '*',
  '+',
  '?',
  '.',
  '^',
  '\$',
  '|'
];
final _ESCAPE_RE = new RegExp('[\\${_RE_SPECIAL_CHARS.join('\\')}]');
RegExp containsRegexp(String input) {
  return new RegExp(
      input.replaceAllMapped(_ESCAPE_RE, (match) => '\\${match[0]}'));
}

RegExp _normalizerExp1,
    _normalizerExp2,
    _normalizerExp3,
    _normalizerExp4,
    _normalizerExp5,
    _normalizerExp6,
    _normalizerExp7;

String normalizeCSS(String css) {
  _normalizerExp1 ??= new RegExp(r'\s+');
  _normalizerExp2 ??= new RegExp(r':\s');
  _normalizerExp3 ??= new RegExp('' + "'" + r'');
  _normalizerExp4 ??= new RegExp('{ ');
  _normalizerExp5 ??= new RegExp(' }');
  _normalizerExp6 ??= new RegExp(r'url\((\"|\s)(.+)(\"|\s)\)(\s*)');
  _normalizerExp7 ??= new RegExp(r'\[(.+)=([^"\]]+)\]');
  css = css.replaceAll(_normalizerExp1, ' ');
  css = css.replaceAll(_normalizerExp2, ':');
  css = css.replaceAll(_normalizerExp3, '"');
  css = css.replaceAll(_normalizerExp4, '{');
  css = css.replaceAll(_normalizerExp5, '}');
  css = css.replaceAllMapped(_normalizerExp6, (match) => 'url("${match[2]}")');
  css = css.replaceAllMapped(
      _normalizerExp7, (match) => '[${match[1]}="${match[2]}"]');
  return css;
}

var _singleTagWhitelist = const ['br', 'hr', 'input'];

String stringifyElement(el) {
  StringBuffer sb = new StringBuffer();
  if (el is Element) {
    var tagName = el.tagName.toLowerCase();
    // Opening tag
    sb.write('<$tagName');
    // Attributes in an ordered way
    var attributeMap = el.attributes;
    var keys = attributeMap.keys.toList();
    keys.sort();
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      var attValue = attributeMap[key];
      if (attValue is! String) {
        sb.write(key);
      } else {
        sb.write('$key="$attValue"');
      }
    }
    sb.write('>');
    // Children
    var childrenRoot = el is TemplateElement ? el.content : el;
    var children = childrenRoot?.childNodes ?? [];
    for (var j = 0; j < children.length; j++) {
      sb.write(stringifyElement(children[j]));
    }
    // Closing tag
    if (!_singleTagWhitelist.contains(tagName)) {
      sb.write('</$tagName>');
    }
  } else if (el is Comment) {
    sb.write('<!--${el.nodeValue}-->');
  } else {
    sb.write(el.text);
  }
  return sb.toString();
}
