import 'dart:html';

final _urlParsingNode = AnchorElement();
Element? _baseElement;

String? baseHrefFromDOM() {
  var href = _getBaseElementHref();
  if (href == null) {
    return null;
  }
  return _relativePath(href);
}

String? _getBaseElementHref() {
  _baseElement ??= document.querySelector('base');
  return _baseElement?.getAttribute('href');
}

// based on urlUtils.js in AngularJS 1.
String _relativePath(String url) {
  _urlParsingNode.href = url;
  var pathname = _urlParsingNode.pathname!;
  return (pathname.isEmpty || pathname[0] == '/') ? pathname : '/$pathname';
}
