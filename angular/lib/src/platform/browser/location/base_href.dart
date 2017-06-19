import 'dart:html';

AnchorElement _urlParsingNode;
Element _baseElement;

String baseHrefFromDOM() {
  var href = _getBaseElementHref();
  if (href == null) {
    return null;
  }
  return _relativePath(href);
}

String _getBaseElementHref() {
  if (_baseElement == null) {
    _baseElement = document.querySelector('base');
    if (_baseElement == null) {
      return null;
    }
  }
  return _baseElement.getAttribute('href');
}

// based on urlUtils.js in AngularJS 1.
String _relativePath(String url) {
  _urlParsingNode ??= new AnchorElement();
  _urlParsingNode.href = url;
  var pathname = _urlParsingNode.pathname;
  return (pathname.isEmpty || pathname[0] == '/') ? pathname : '/$pathname';
}
